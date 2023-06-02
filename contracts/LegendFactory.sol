// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LegendKeeper.sol";
import "./LegendAccessControl.sol";
import "./LegendDynamicNFT.sol";
import "./GlobalLegendAccessControl.sol";

contract LegendFactory {
    GlobalLegendAccessControl private _accessControl;
    string public name;
    string public symbol;

    struct Grant {
        address[3] contracts;
        string name;
        uint256 timestamp;
        string status;
    }

    event AccessControlSet(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    event FactoryDeployed(
        address keeperAddress,
        address accessControlAddress,
        address dynamicNFTAddress,
        string name,
        address indexed deployer,
        uint256 timestamp
    );

    event GrantStatusUpdated(address deployerAddress, string status);

    mapping(address => mapping(string => Grant)) private _deployerToGrant;
    mapping(address => address[]) private _deployedLegendKeepers;
    mapping(address => address[]) private _deployedLegendAccessControls;
    mapping(address => address[]) private _deployedLegendDynamicNFTs;
    mapping(address => uint256[]) private _deployerTimestamps;

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyDynamicNFT(
        address _deployerAddress,
        string memory _grantName,
        address _dynamicNFTAddress
    ) {
        require(
            _deployerToGrant[_deployerAddress][_grantName].contracts[2] ==
                _dynamicNFTAddress,
            "LegendFactory: Only the Dynamic NFT Address can update the grant status"
        );

        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _accessControlsAddress
    ) {
        name = _name;
        symbol = _symbol;
        _accessControl = GlobalLegendAccessControl(_accessControlsAddress);
    }

    function createContracts(
        uint256 _pubId,
        uint256 _profileId,
        DynamicNFTLibrary.ConstructorArgs memory args
    ) public {
        address _grantDeployer = msg.sender;

        require(
            bytes(_deployerToGrant[_grantDeployer][args.grantNameValue].name)
                .length == 0,
            "LegendFactory: Grant Name must be unique."
        );

        // Deploy LegendAccessControl
        LegendAccessControl newLegendAccessControl = new LegendAccessControl(
            "Legend AccessControl",
            "LAC",
            _grantDeployer
        );

        // Deploy LegendDynamicNFT
        LegendDynamicNFT newLegendDynamicNFT = new LegendDynamicNFT(
            args,
            address(newLegendAccessControl),
            address(this),
            _grantDeployer
        );

        // Deploy LegendKeeper
        LegendKeeper newLegendKeeper = new LegendKeeper(
            args.editionAmountValue,
            _pubId,
            _profileId,
            args.lensHubProxyAddress,
            address(newLegendDynamicNFT),
            address(newLegendAccessControl),
            _grantDeployer,
            "Legend Keeper",
            "LKEEP"
        );

        newLegendDynamicNFT.setLegendKeeperAddress(address(newLegendKeeper));

        _accessControl.addWriter(_grantDeployer);

        Grant memory grantDetails = Grant(
            [
                address(newLegendKeeper),
                address(newLegendAccessControl),
                address(newLegendDynamicNFT)
            ],
            args.grantNameValue,
            block.timestamp,
            "live"
        );

        _deployerToGrant[_grantDeployer][args.grantNameValue] = grantDetails;

        _deployedLegendKeepers[_grantDeployer].push(address(newLegendKeeper));
        _deployedLegendDynamicNFTs[_grantDeployer].push(
            address(newLegendDynamicNFT)
        );
        _deployedLegendAccessControls[_grantDeployer].push(
            address(newLegendAccessControl)
        );

        emit FactoryDeployed(
            address(newLegendKeeper),
            address(newLegendAccessControl),
            address(newLegendDynamicNFT),
            args.grantNameValue,
            msg.sender,
            block.timestamp
        );
    }

    function getDeployedLegendKeepers(address _deployerAddress)
        public
        view
        returns (address[] memory)
    {
        return _deployedLegendKeepers[_deployerAddress];
    }

    function getDeployedLegendAccessControls(address _deployerAddress)
        public
        view
        returns (address[] memory)
    {
        return _deployedLegendAccessControls[_deployerAddress];
    }

    function getDeployedLegendDynamicNFTs(address _deployerAddress)
        public
        view
        returns (address[] memory)
    {
        return _deployedLegendDynamicNFTs[_deployerAddress];
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function setAccessControl(address _newAccessControlAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlSet(oldAddress, _newAccessControlAddress, msg.sender);
    }

    function getGrantName(address _deployerAddress, string memory _grantName)
        public
        view
        returns (string memory)
    {
        return _deployerToGrant[_deployerAddress][_grantName].name;
    }

    function getGrantContracts(
        address _deployerAddress,
        string memory _grantName
    ) public view returns (address[3] memory) {
        return _deployerToGrant[_deployerAddress][_grantName].contracts;
    }

    function getGrantTimestamp(
        address _deployerAddress,
        string memory _grantName
    ) public view returns (uint256) {
        return _deployerToGrant[_deployerAddress][_grantName].timestamp;
    }

    function getGrantStatus(address _deployerAddress, string memory _grantName)
        public
        view
        returns (string memory)
    {
        return _deployerToGrant[_deployerAddress][_grantName].status;
    }

    function setGrantStatus(
        address _deployerAddress,
        string memory _newStatus,
        string memory _grantName
    ) external onlyDynamicNFT(_deployerAddress, _grantName, msg.sender) {
        _deployerToGrant[_deployerAddress][_grantName].status = _newStatus;
        emit GrantStatusUpdated(_deployerAddress, _newStatus);
    }
}
