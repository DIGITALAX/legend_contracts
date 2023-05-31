// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./LegendDynamicNFT.sol";
import "./LegendAccessControl.sol";

interface ILensHubProxy {
    function defaultProfile(address wallet) external view returns (uint256);

    function getCollectNFT(uint256 profileId, uint256 pubId)
        external
        view
        returns (address);
}

interface ICollectNFT {
    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

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

    ICollectNFT private _collectNFT;
    ILensHubProxy private _lensHubProxy;
    LegendDynamicNFT private _legendDynamicNFT;
    LegendAccessControl private _legendAccessControl;

    modifier onlyAdmin() {
        require(
            _legendAccessControl.isAdmin(msg.sender),
            "LegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    constructor(
        uint256 _editionAmountValue,
        uint256 _pubIdValue,
        uint256 _profileIdValue,
        address _lensHubProxyAddress,
        address _legendDynamicNFTAddress,
        address _accessControlAddress,
        address _deployerAddressValue,
        string memory _name,
        string memory _symbol
    ) {
        _editionAmount = _editionAmountValue;
        _totalAmountOfCollects = 0;
        _currentCollects = 0;
        _deployerAddress = _deployerAddressValue;

        _lensHubProxy = ILensHubProxy(_lensHubProxyAddress);
        _legendDynamicNFT = LegendDynamicNFT(_legendDynamicNFTAddress);
        _legendAccessControl = LegendAccessControl(_accessControlAddress);

        symbol = _symbol;
        name = _name;
        _pubId = _pubIdValue;
        _profileId = _profileIdValue;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        _returnValues();

        upkeepNeeded = _currentCollects > _totalAmountOfCollects;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if (_currentCollects > _totalAmountOfCollects) {
            _totalAmountOfCollects = _currentCollects;
            _legendDynamicNFT.updateMetadata(_totalAmountOfCollects);
        }
    }

    function _returnValues() private {
        if (address(_collectNFT) == address(0)) {
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

    function _setCollectNFTAddress(address _collectNFTAddress) private {
        require(address(_collectNFT) == address(0));
        _collectNFT = ICollectNFT(_collectNFTAddress);
    }

    function setKeeperId(uint256 _keeperIdValue) public onlyAdmin {
        require(_keeperId == 0, "LegendKeeper: KeeperId already set.");
        _keeperId = _keeperIdValue;
    }

    function getCollectionNFTAddress() private view returns (address) {
        return address(_collectNFT);
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

    function getDynamicNFTAddress() public view returns (address) {
        return address(_legendDynamicNFT);
    }

    function getAccessControlAddress() public view returns (address) {
        return address(_legendAccessControl);
    }
}
