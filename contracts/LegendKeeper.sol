// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "/Users/devdesign/Documents/DIGITALAX_Code/legend/node_modules/@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "abis/LensHubProxy.json";
import "abis/CollectNFT.json";
import "./LegendDynamicNFT.sol";

contract LegendKeeper is AutomationCompatibleInterface {
    string public symbol;
    string public name;
    uint256 private pubId;
    uint256 private profileId;
    uint256 private editionAmount;
    uint256 private keeperId;
    uint256 private totalAmountOfCollects;
    uint256 private currentCollects;
    address private deployerAddress;

    CollectNFTContract private collectNFTContract;
    LensHubProxyContract private lensHubProxyContract;
    LegendDynamicNFT private legendDynamicNFT;
    KeeperRegistryContract private keeperRegistryContract;
    LegendAccessControlContract private legendAccessControlContract;

    modifier onlyAdmin() {
        require(
            legendAccessControl.isAdmin(msg.sender),
            "LegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    constructor(
        uint256 _editionAmount,
        address _lensHubProxyContract,
        address _legendDynamicNFT,
        address _keeperRegistryContract,
        address _legendAccessControlContract,
        string memory _name,
        string memory _symbol
    ) {
        editionAmount = _editionAmount;
        totalAmountOfCollects = 0;
        currentCollects = 0;
        deployerAddress = msg.sender;

        lensHubProxyContract = LensHubProxyContract(_lensHubProxyContract);
        legendDynamicNFT = LegendDynamicNFT(_legendDynamicNFT);
        keeperRegistryContract = KeeperRegistryContract(
            _keeperRegistryContract
        );
        legendAccessControlContract = LegendAccessControlContract(
            _legendAccessControlContract
        );

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

        upkeepNeeded = currentCollects > totalAmountOfCollects;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (currentCollects > totalAmountOfCollects) {
            totalAmountOfCollects = currentCollects;
            legendDynamicNFT.updateMetadata(totalAmountOfCollects);
        }
    }

    function _returnValues() private {
        if (profileId == 0) {
            uint256 _profileId = lensHubProxyContract.getDefaultProfile();
            _setProfileId(_profileId);
        }

        if (pubId != 0 && collectNFTContract == address(0)) {
            address collectNFT = lensHubProxyContract.getCollectNFT(
                profileId,
                pubId
            );

            // if the collectNFT address has not been set and the there has been collected editions of the post, set the collectNFT contract address and update the current collect amount
            if (collectNFT != address(0)) {
                _setCollectNFTAddress(collectNFT);

                currentCollects = collectNFTContract.totalSupply();
            }
        }
    }

    function cancelUpkeep() external returns (bool success) {
        keeperRegistryContract.cancelUpkeep(keeperId);
        return true;
    }

    function _setCollectNFTAddress(address _collectNFTContract) private {
        require(collectNFTContract == address(0));
        collectNFTContract = CollectNFTContract(_collectNFTContract);
    }

    function _setProfileId(uint256 _profileId) private {
        require(profileId == 0, "LegendKeeper: ProfileId already set.");
        profileId = _profileId;
    }

    function setPubId(uint256 _pubId) public onlyAdmin {
        require(pubId == 0, "LegendKeeper: PubId already set.");
        pubId = _pubId;
    }

    function setKeeperId(uint256 _keeperId) public onlyAdmin {
        require(keeperId == 0, "LegendKeeper: KeeperId already set.");
        keeperId = _keeperId;
    }

    function getProfileId() public view returns (uint256) {
        return profileId;
    }

    function getPostId() public view onlyAdmin returns (uint256) {
        return pubId;
    }

    function getKeeperId() public view returns (uint256) {
        return keeperId;
    }

    function getEditionAmount() public view returns (uint256) {
        return editionAmount;
    }

    function getDeployerAddress() public view returns (address) {
        return deployerAddress;
    }

    function getTotalAmountOfCollects() public view returns (uint256) {
        return totalAmountOfCollects;
    }

    function getCurrentCollects() public view returns (uint256) {
        return currentCollects;
    }
}
