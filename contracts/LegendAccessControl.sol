// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract LegendAccessControl {
    string public symbol;
    string public name;
    address public admin;

    event AdminRemoved(address indexed _newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admins can perform this action");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        symbol = _symbol;
        name = _name;
        admin = msg.sender;
    }

    function removeAndUpdateAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
        emit AdminRemoved(_newAdmin);
    }

    function isAdmin(address _address) public view returns (bool) {
        return _address == admin;
    }
}
