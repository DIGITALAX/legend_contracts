// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "./LegendKeeper.sol";
import "./LegendAccessControl.sol";
import "abis/CollectNFT.json";

contract LegendDynamicNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    uint256 private editionAmount;
    string[] private URIArray;

    mapping(uint256 => address) private collectorMapping;

    Counters.Counter private _tokenIdCounter;
    CollectNFT private _collectNFT;
    LegendKeeper private _legendKeeper;
    LegendAccessControl private _legendAccessControl;

    modifier onlyAdmin() {
        require(
            legendAccessControl.isAdmin(msg.sender),
            "LegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyKeeper() {
        require(
            msg.sender == address(_legendKeeper),
            "LegendDynamicNFT: Only the Keeper Contract can perform this action"
        );
        _;
    }

    modifier onlyCollector() {
        require(
            _collectNFT.balanceOf(msg.sender) > 0,
            "LegendDynamicNFT: Only Publication Collectors can perform this action"
        );
        _;
    }

    constructor(
        address _legendAccessControlAddress,
        string[] memory _URIArray,
        uint256 _editionAmount
    ) ERC721("LegendKeeper", "LKEEP") {
        editionAmount = _editionAmount;
        URIArray = _URIArray;
        _legendAccessControl = LegendAccessControl(_legendAccessControlAddress);
    }

    function safeMint(address _to) external onlyCollector {
        // collector can only mint1, total amount must be less than max supply
        require();
        
        uint256 _tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(_to, tokenId);

        // Default to 0
        string memory _defaultUri = URIArray[0];
        _setTokenURI(_tokenId, _defaultUri);
    }

    function updateMetadata(uint256 _totalAmountOfCollects) external onlyKeeper {
        if (_totalAmountOfCollects > editionAmount) return;

        // update new uri for all tokenids

        _setTokenURI(tokenId, _tokenURI);

    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _burn(
        uint256 _tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(_tokenId);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function setLegendKeeperContract(
        address _legendKeeperContract
    ) public onlyAdmin {
        _legendKeeper = LegendKeeper(_legendKeeperContract);
    }

    function setCollectNFTAddress(
        address _collectNFTAddress
    ) external onlyKeeper {
        require(_collectNFT == address(0));
        _collectNFT = CollectNFT(_collectNFTAddress);
    }

    function getEditionAmount() public view returns (uint256) {
        return editionAmount;
    }
}
