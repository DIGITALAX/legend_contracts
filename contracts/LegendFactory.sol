// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LegendKeeper.sol";
import "./LegendAccessControl.sol";
import "./LegendDynamicNFT.sol";
import "./GlobalLegendAccessControl.sol";

contract LegendFactory {
    GlobalLegendAccessControl private _accessControl;

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
    mapping(address => Grant) private _deployerToGrant;
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

    function createContracts(
        uint256 _editionAmountValue,
        address _lensHubProxyAddress,
        string[] memory _URIArrayValue,
        address _externalOwner,
        string memory _name
    ) public {
        uint256 blockTimestamp = block.timestamp;
        // Deploy LegendAccessControl
        LegendAccessControl newLegendAccessControl = new LegendAccessControl(
            "Legend AccessControl",
            "LAC",
            _externalOwner
        );

        // Deploy LegendDynamicNFT
        LegendDynamicNFT newLegendDynamicNFT = new LegendDynamicNFT(
            address(newLegendAccessControl),
            _lensHubProxyAddress,
            address(this),
            _externalOwner,
            _URIArrayValue,
            _editionAmountValue
        );

        // Deploy LegendKeeper
        LegendKeeper newLegendKeeper = new LegendKeeper(
            _editionAmountValue,
            _lensHubProxyAddress,
            address(newLegendDynamicNFT),
            address(newLegendAccessControl),
            "Legend Keeper",
            "LKEEP"
        );

        // Set LegendKeeper in LegendDynamicNFT contract
        newLegendDynamicNFT.setLegendKeeperContract(address(newLegendKeeper));

        _deployerToContracts[_externalOwner][blockTimestamp].push(
            address(newLegendKeeper)
        );
        _deployerToContracts[_externalOwner][blockTimestamp].push(
            address(newLegendAccessControl)
        );
        _deployerToContracts[_externalOwner][blockTimestamp].push(
            address(newLegendDynamicNFT)
        );

        _accessControl.addWriter(_externalOwner);

        Grant memory grantDetails = Grant(
            [
                address(newLegendKeeper),
                address(newLegendAccessControl),
                address(newLegendDynamicNFT)
            ],
            _name,
            block.timestamp,
            "live"
        );

        _deployerToGrant[_externalOwner] = grantDetails;

        _deployedLegendKeepers[_externalOwner] = address(newLegendKeeper);
        _deployedLegendDynamicNFTs[_externalOwner] = address(
            newLegendDynamicNFT
        );
        _deployedLegendAccessControls[_externalOwner] = address(
            newLegendAccessControl
        );

        emit FactoryDeployed(
            address(newLegendKeeper),
            address(newLegendAccessControl),
            address(newLegendDynamicNFT),
            _name,
            _externalOwner,
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

    function getGrantName(address _deployerAddress)
        public
        view
        returns (string memory)
    {
        return _deployerToGrant[_deployerAddress].name;
    }

    function getGrantContracts(address _deployerAddress)
        public
        view
        returns (address[3] memory)
    {
        return _deployerToGrant[_deployerAddress].contracts;
    }

    function getGrantTimestamp(address _deployerAddress)
        public
        view
        returns (uint256)
    {
        return _deployerToGrant[_deployerAddress].timestamp;
    }

    function getGrantStatus(address _deployerAddress)
        public
        view
        returns (string memory)
    {
        return _deployerToGrant[_deployerAddress].status;
    }

    function setGrantStatus(address _deployerAddress, string memory _newStatus)
        external
        onlyDeployerDynamicNFT(_deployerAddress)
    {
        _deployerToGrant[_deployerAddress].status = _newStatus;
        emit GrantStatusUpdated(_deployerAddress, _newStatus);
    }
}
