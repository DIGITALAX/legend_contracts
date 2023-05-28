// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AccessControl.sol";

contract LegendPayment {
    AccessControl public accessControl;
    address[] public verifiedPaymentTokens;

    mapping(address => bool) private isVerifiedPaymentToken;

    modifier onlyAdmin() {
        require(
            accessControl.isAdmin(msg.sender),
            "AccessControl: Only admin can perform this action"
        );
        _;
    }

    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    constructor(address _accessControlAddress) {
        accessControl = AccessControl(_accessControlAddress);
    }

    function setVerifiedPaymentTokens(
        address[] memory _paymentTokens
    ) public onlyAdmin {
        for (uint256 i = 0; i < verifiedPaymentTokens.length; i++) {
            isVerifiedPaymentToken[verifiedPaymentTokens[i]] = false;
        }
        delete verifiedPaymentTokens;

        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            isVerifiedPaymentToken[_paymentTokens[i]] = true;
            verifiedPaymentTokens.push(_paymentTokens[i]);
        }
    }

    function getVerifiedPaymentTokens() public view returns (address[] memory) {
        return verifiedPaymentTokens;
    }

    function updateAccessControl(
        address _newAccessControlAddress
    ) external onlyAdmin {
        address oldAddress = address(accessControl);
        accessControl = AccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function checkIfAddressVerified(
        address _address
    ) public view returns (bool) {
        return isVerifiedPaymentToken[_address];
    }
}
