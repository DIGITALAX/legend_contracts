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

    mapping(address => mapping(uint256 => address[]))
        private _deployerToContracts;
    mapping(address => mapping(string => Grant)) private _deployerToGrant;
    mapping(address => address) private _deployedLegendKeepers;
    mapping(address => address) private _deployedLegendAccessControls;
    mapping(address => address) private _deployedLegendDynamicNFTs;

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyDeployerDynamicNFT(address _deployerAddress) {
        require(
            msg.sender == _deployedLegendDynamicNFTs[_deployerAddress],
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
        uint256 blockTimestamp = block.timestamp;
        // Deploy LegendAccessControl
        LegendAccessControl newLegendAccessControl = new LegendAccessControl(
            "Legend AccessControl",
            "LAC",
            args.deployerAddressValue
        );

        // Deploy LegendDynamicNFT
        LegendDynamicNFT newLegendDynamicNFT = new LegendDynamicNFT(
            args,
            address(newLegendAccessControl),
            address(this)
        );

        // Deploy LegendKeeper
        LegendKeeper newLegendKeeper = new LegendKeeper(
            args.editionAmountValue,
            _pubId,
            _profileId,
            args.lensHubProxyAddress,
            address(newLegendDynamicNFT),
            address(newLegendAccessControl),
            args.deployerAddressValue,
            "Legend Keeper",
            "LKEEP"
        );

        newLegendDynamicNFT.setLegendKeeperAddress(address(newLegendKeeper));

        _deployerToContracts[args.deployerAddressValue][blockTimestamp].push(
            address(newLegendKeeper)
        );
        _deployerToContracts[args.deployerAddressValue][blockTimestamp].push(
            address(newLegendAccessControl)
        );
        _deployerToContracts[args.deployerAddressValue][blockTimestamp].push(
            address(newLegendDynamicNFT)
        );

        _accessControl.addWriter(args.deployerAddressValue);

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

        _deployerToGrant[args.deployerAddressValue][
            args.grantNameValue
        ] = grantDetails;

        _deployedLegendKeepers[args.deployerAddressValue] = address(
            newLegendKeeper
        );
        _deployedLegendDynamicNFTs[args.deployerAddressValue] = address(
            newLegendDynamicNFT
        );
        _deployedLegendAccessControls[args.deployerAddressValue] = address(
            newLegendAccessControl
        );

        emit FactoryDeployed(
            address(newLegendKeeper),
            address(newLegendAccessControl),
            address(newLegendDynamicNFT),
            args.grantNameValue,
            args.deployerAddressValue,
            block.timestamp
        );
    }

    function getDeployedLegendKeepers(address _deployerAddress)
        public
        view
        returns (address)
    {
        return _deployedLegendKeepers[_deployerAddress];
    }

    function getDeployedLegendAccessControls(address _deployerAddress)
        public
        view
        returns (address)
    {
        return _deployedLegendAccessControls[_deployerAddress];
    }

    function getDeployedLegendDynamicNFTs(address _deployerAddress)
        public
        view
        returns (address)
    {
        return _deployedLegendDynamicNFTs[_deployerAddress];
    }

    function getDeployerToContracts(address _address)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] storage contracts = _deployerToContracts[_address][
            block.timestamp
        ];

        address[] memory contractAddresses = new address[](contracts.length);
        uint256[] memory timestamps = new uint256[](contracts.length);

        for (uint256 i = 0; i < contracts.length; i++) {
            contractAddresses[i] = contracts[i];
            timestamps[i] = block.timestamp;
        }

        return (contractAddresses, timestamps);
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
    ) external onlyDeployerDynamicNFT(_deployerAddress) {
        _deployerToGrant[_deployerAddress][_grantName].status = _newStatus;
        emit GrantStatusUpdated(_deployerAddress, _newStatus);
    }
}
