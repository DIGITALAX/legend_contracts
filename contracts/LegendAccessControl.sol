// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract LegendAccessControl {
    string public symbol;
    string public name;

    mapping(address => bool) private admins;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    modifier onlyAdmin() {
        require(
            admins[msg.sender],
            "LegendAcessControl: Only admins can perform this action"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _externalOwner
    ) {
        symbol = _symbol;
        name = _name;
        admins[_externalOwner] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        require(
            !admins[_admin] && _admin != msg.sender,
            "Cannot add existing admin or yourself"
        );
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(_admin != msg.sender, "Cannot remove yourself as admin");
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }
}
