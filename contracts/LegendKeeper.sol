// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "node_modules/@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "abis/LensHubProxy.json";
import "abis/CollectNFT.json";
import "./LegendDynamicNFT.sol";
import "./LegendAccessControl.sol";

contract LegendKeeper is AutomationCompatibleInterface {
    string public symbol;
    string public name;
    uint256 private _pubId;
    uint256 private _profileId;
    uint256 private _editionAmount;
    uint256 private _keeperId;
    uint256 private _totalAmountOfCollects;
    uint256 private _currentCollects;
    address private _deployerAddress;

    CollectNFT private _collectNFT;
    LensHubProxy private _lensHubProxy;
    LegendDynamicNFT private _legendDynamicNFT;
    KeeperRegistry private _keeperRegistry;
    LegendAccessControl private _legendAccessControl;

    modifier onlyAdmin() {
        require(
            legendAccessControl.isAdmin(msg.sender),
            "LegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    constructor(
        uint256 _editionAmountValue,
        address _lensHubProxyAddress,
        address _legendDynamicNFTAddress,
        address _keeperRegistryAddress,
        address _legendAccessControlAddress,
        string memory _name,
        string memory _symbol
    ) {
        _editionAmount = _editionAmountValue;
        _totalAmountOfCollects = 0;
        _currentCollects = 0;
        _deployerAddress = msg.sender;

        _lensHubProxy = LensHubProxy(_lensHubProxyAddress);
        _legendDynamicNFT = LegendDynamicNFT(_legendDynamicNFTAddress);
        _keeperRegistry = KeeperRegistry(_keeperRegistryAddress);
        _legendAccessControl = LegendAccessControl(_legendAccessControlAddress);

        symbol = _symbol;
        name = _name;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        _returnValues();

        upkeepNeeded = _currentCollects > _totalAmountOfCollects;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (_currentCollects > _totalAmountOfCollects) {
            _totalAmountOfCollects = _currentCollects;
            legendDynamicNFT.updateMetadata(_totalAmountOfCollects);
        }
    }

    function _returnValues() private {
        if (_profileId == 0) {
            uint256 _profileIdValue = _lensHubProxy.getDefaultProfile();
            _setProfileId(_profileIdValue);
        }

        if (pubId != 0 && _collectNFT == address(0)) {
            address collectNFTAddress = _lensHubProxy.getCollectNFT(
                _profileId,
                _pubId
            );

            // if the collectNFT address has not been set and the there has been collected editions of the post, set the collectNFT  address and update the current collect amount
            if (collectNFTAddress != address(0)) {
                _setCollectNFTAddress(collectNFTAddress);

                _currentCollects = _collectNFT.totalSupply();
            }
        }
    }

    function cancelUpkeep() external returns (bool success) {
        keeperRegistry.cancelUpkeep(_keeperId);
        return true;
    }

    function _setCollectNFTAddress(address _collectNFTAddress) private {
        require(_collectNFT == address(0));
        _collectNFT = CollectNFT(_collectNFTAddress);
    }

    function _setProfileId(uint256 _profileIdValue) private {
        require(_profileId == 0, "LegendKeeper: ProfileId already set.");
        profileId = _profileIdValue;
    }

    function setPubId(uint256 _pubIdValue) public onlyAdmin {
        require(_pubId == 0, "LegendKeeper: PubId already set.");
        pubId = _pubIdValue;
    }

    function setKeeperId(uint256 _keeperIdValue) public onlyAdmin {
        require(_keeperId == 0, "LegendKeeper: KeeperId already set.");
        keeperId = _keeperIdValue;
    }

    function getCollectionNFTAddress() public returns (address) {
        return _collectNFT;
    }

    function getProfileId() public view returns (uint256) {
        return _profileId;
    }

    function getPostId() public view returns (uint256) {
        return _pubId;
    }

    function getKeeperId() public view returns (uint256) {
        return _keeperId;
    }

    function getEditionAmount() public view returns (uint256) {
        return _editionAmount;
    }

    function getDeployerAddress() public view returns (address) {
        return _deployerAddress;
    }

    function getTotalAmountOfCollects() public view returns (uint256) {
        return _totalAmountOfCollects;
    }

    function getCurrentCollects() public view returns (uint256) {
        return _currentCollects;
    }
}
