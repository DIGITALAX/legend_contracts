// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LegendKeeper.sol";
import "./LegendAccessControl.sol";
import "./LegendDynamicNFT.sol";

contract LegendFactory {
    address[] private deployedLegendKeepers;
    address[] private deployedLegendAccessControls;
    address[] private deployedLegendDynamicNFTs;

    mapping(address => address[]) private deployerToContracts;

    function createContracts(
        uint256 _editionAmountValue,
        address _lensHubProxyAddress,
        string memory _name,
        string memory _symbol,
        string[] memory _URIArrayValue,
        string memory _nameAC,
        string memory _symbolAC
    ) public {
        // Deploy LegendAccessControl
        LegendAccessControl newLegendAccessControl = new LegendAccessControl(
            _nameAC,
            _symbolAC
        );

        deployedLegendAccessControls.push(address(newLegendAccessControl));

        // Deploy LegendDynamicNFT
        LegendDynamicNFT newLegendDynamicNFT = new LegendDynamicNFT(
            address(newLegendAccessControl),
            _lensHubProxyAddress,
            _URIArrayValue,
            _editionAmountValue
        );

        deployedLegendDynamicNFTs.push(address(newLegendDynamicNFT));

        // Deploy LegendKeeper
        LegendKeeper newLegendKeeper = new LegendKeeper(
            _editionAmountValue,
            _lensHubProxyAddress,
            address(newLegendDynamicNFT),
            address(newLegendAccessControl),
            _name,
            _symbol
        );

        deployedLegendKeepers.push(address(newLegendKeeper));

        // Set LegendKeeper in LegendDynamicNFT contract
        newLegendDynamicNFT.setLegendKeeperContract(address(newLegendKeeper));

        deployerToContracts[msg.sender].push(address(newLegendKeeper));
        deployerToContracts[msg.sender].push(address(newLegendAccessControl));
        deployerToContracts[msg.sender].push(address(newLegendDynamicNFT));
    }

    function getDeployedLegendKeepers() public view returns (address[] memory) {
        return deployedLegendKeepers;
    }

    function getDeployedLegendAccessControls()
        public
        view
        returns (address[] memory)
    {
        return deployedLegendAccessControls;
    }

    function getDeployedLegendDynamicNFTs()
        public
        view
        returns (address[] memory)
    {
        return deployedLegendDynamicNFTs;
    }

    function getDeployerToContracts(address _address)
        public
        view
        returns (address[] memory)
    {
        return deployerToContracts[_address];
    }
}
