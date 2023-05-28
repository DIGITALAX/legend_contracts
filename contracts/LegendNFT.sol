// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendCollection.sol";
import "./AccessControl.sol";
import "./LegendEscrow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract LegendNFT is ERC721Enumerable {
    AccessControl public accessControl;
    LegendEscrow public legendEscrow;
    LegendCollection public legendCollection;
    uint256 public totalSupplyCount;

    struct Token {
        uint256 tokenId;
        uint256 collectionId;
        address[] acceptedTokens;
        uint256[] basePrices;
        address creator;
        string uri;
        bool isBurned;
        uint256 timestamp;
        bool fulfillment;
    }

    mapping(uint256 => Token) private tokens;

    event BatchTokenMinted(address indexed to, uint256[] tokenIds, string uri);
    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );
    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
        address updater
    );
    event LegendEscrowUpdated(
        address indexed oldLegendEscrow,
        address indexed newLegendEscrow,
        address updater
    );
    event TokenBurned(uint256 indexed tokenId);
    event TokenBasePriceUpdated(
        uint256 indexed tokenId,
        uint256[] oldPrice,
        uint256[] newPrice,
        address updater
    );
    event TokenAcceptedTokensUpdated(
        uint256 indexed tokenId,
        address[] oldAcceptedTokens,
        address[] newAcceptedTokens,
        address updater
    );
    event TokenURIUpdated(
        uint256 indexed tokenId,
        string oldURI,
        string newURI,
        address updater
    );
    event TokenFulfillmentUpdated(uint256 indexed tokenId, address updater);

    modifier onlyAdmin() {
        require(
            accessControl.isAdmin(msg.sender),
            "AccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyCreator(uint256 _tokenId) {
        require(
            tokens[_tokenId].creator == msg.sender,
            "LegendNFT: Only Token Creator Can Update Token URI"
        );
        _;
    }

    modifier onlyCollectionContract() {
        require(
            msg.sender == address(legendCollection),
            "LegendNFT: Only collection contract can mint tokens"
        );
        _;
    }

    modifier tokensInEscrow(uint256 _tokenId) {
        require(
            ownerOf(_tokenId) == address(legendEscrow),
            "LegendNFT: Tokens can only be edited when whole collection is in Escrow"
        );
        _;
    }

    constructor(address _accessControlAddress) ERC721("LegendNFT", "CHRON") {
        accessControl = AccessControl(_accessControlAddress);
        totalSupplyCount = 0;
    }

    function mintBatch(
        string memory _uri,
        uint256 _amount,
        uint256 _collectionId,
        address _creator,
        address[] memory _acceptedTokens,
        uint256[] memory _basePrices
    ) public onlyCollectionContract {
        uint256[] memory tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            totalSupplyCount += 1;
            Token memory newToken = Token({
                tokenId: totalSupplyCount,
                collectionId: _collectionId,
                acceptedTokens: _acceptedTokens,
                basePrices: _basePrices,
                creator: _creator,
                uri: _uri,
                isBurned: false,
                timestamp: block.timestamp,
                fulfillment: false
            });

            tokens[totalSupplyCount] = newToken;
            tokenIds[i] = totalSupplyCount;
            _safeMint(address(legendEscrow), totalSupplyCount);
            legendEscrow.deposit(totalSupplyCount, true);
        }

        emit BatchTokenMinted(address(legendEscrow), tokenIds, _uri);
    }

    function burnBatch(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                msg.sender == ownerOf(_tokenIds[i]),
                "ERC721Metadata: Only token owner can burn tokens"
            );
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            burn(_tokenIds[i]);
        }
    }

    function burn(uint256 _tokenId) public {
        require(
            msg.sender == ownerOf(_tokenId),
            "ERC721Metadata: Only token owner can burn token"
        );
        _burn(_tokenId);
        tokens[_tokenId].isBurned = true;
        emit TokenBurned(_tokenId);
    }

    function setLegendCollection(
        address _legendCollectionAddress
    ) external onlyAdmin {
        address oldAddress = address(legendCollection);
        legendCollection = LegendCollection(_legendCollectionAddress);
        emit LegendCollectionUpdated(
            oldAddress,
            _legendCollectionAddress,
            msg.sender
        );
    }

    function setLegendEscrow(
        address _legendEscrowAddress
    ) external onlyAdmin {
        address oldAddress = address(legendEscrow);
        legendEscrow = LegendEscrow(_legendEscrowAddress);
        emit LegendEscrowUpdated(
            oldAddress,
            _legendEscrowAddress,
            msg.sender
        );
    }

    function updateAccessControl(
        address _newAccessControlAddress
    ) public onlyAdmin {
        address oldAddress = address(accessControl);
        accessControl = AccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return tokens[_tokenId].uri;
    }

    function getTokenCreator(uint256 _tokenId) public view returns (address) {
        return tokens[_tokenId].creator;
    }

    function getTokenAcceptedTokens(
        uint256 _tokenId
    ) public view returns (address[] memory) {
        return tokens[_tokenId].acceptedTokens;
    }

    function getBasePrices(
        uint256 _tokenId
    ) public view returns (uint256[] memory) {
        return tokens[_tokenId].basePrices;
    }

    function getTokenCollection(
        uint256 _tokenId
    ) public view returns (uint256) {
        return tokens[_tokenId].collectionId;
    }

    function getTokenIsBurned(uint256 _tokenId) public view returns (bool) {
        return tokens[_tokenId].isBurned;
    }

    function getTokenTimestamp(uint256 _tokenId) public view returns (uint256) {
        return tokens[_tokenId].timestamp;
    }

    function getTokenId(uint256 _tokenId) public view returns (uint256) {
        return tokens[_tokenId].tokenId;
    }

    function getTokenFulfilled(uint256 _tokenId) public view returns (bool) {
        return tokens[_tokenId].fulfillment;
    }

    function setTokenAcceptedTokens(
        uint256 _tokenId,
        address[] memory _newAcceptedTokens
    ) public onlyCollectionContract tokensInEscrow(_tokenId) {
        address[] memory oldTokens = tokens[_tokenId].acceptedTokens;
        tokens[_tokenId].acceptedTokens = _newAcceptedTokens;
        emit TokenAcceptedTokensUpdated(
            _tokenId,
            oldTokens,
            _newAcceptedTokens,
            msg.sender
        );
    }

    function setBasePrices(
        uint256 _tokenId,
        uint256[] memory _newPrices
    ) public onlyCollectionContract tokensInEscrow(_tokenId) {
        uint256[] memory oldPrices = tokens[_tokenId].basePrices;
        tokens[_tokenId].basePrices = _newPrices;
        emit TokenBasePriceUpdated(_tokenId, oldPrices, _newPrices, msg.sender);
    }

    function setTokenFulfilled(uint256 _tokenId) public onlyCollectionContract {
        tokens[_tokenId].fulfillment = true;
        emit TokenFulfillmentUpdated(_tokenId, msg.sender);
    }

    function setTokenURI(
        uint256 _tokenId,
        string memory _newURI
    ) public onlyCollectionContract tokensInEscrow(_tokenId) {
        string memory oldURI = tokens[_tokenId].uri;
        tokens[_tokenId].uri = _newURI;
        emit TokenURIUpdated(_tokenId, oldURI, _newURI, msg.sender);
    }
}
