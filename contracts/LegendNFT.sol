// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendCollection.sol";
import "./GlobalLegendAccessControl.sol";
import "./LegendEscrow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract LegendNFT is ERC721Enumerable {
    GlobalLegendAccessControl private _accessControl;
    LegendEscrow private _legendEscrow;
    LegendCollection private _legendCollection;
    uint256 private _totalSupplyCount;

    struct Token {
        uint256 tokenId;
        uint256 collectionId;
        address[] acceptedTokens;
        uint256[] basePrices;
        address creator;
        string uri;
        bool isBurned;
        uint256 timestamp;
        uint256 fulfillerId;
        string printType;
        uint256 discount;
        bool grantCollectorsOnly;
        uint256 pubId;
        address dynamicNFTAddress;
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
    event TokenFulfillerIdUpdated(
        uint256 indexed tokenId,
        uint256 oldFulfillerId,
        uint256 newFulfillerId,
        address updater
    );
    event TokenPrintTypeUpdated(
        uint256 indexed tokenId,
        string oldPrintType,
        string newPrintType,
        address updater
    );
    event TokenGrantCollectorsOnlyUpdated(
        uint256 indexed tokenId,
        bool collectorsOnly,
        address updater
    );
    event TokenDiscountUpdated(
        uint256 indexed tokenId,
        uint256 discount,
        address updater
    );

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "AccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyCollectionContract() {
        require(
            msg.sender == address(_legendCollection),
            "LegendNFT: Only collection contract can mint tokens"
        );
        _;
    }

    modifier tokensInEscrow(uint256 _tokenId) {
        require(
            ownerOf(_tokenId) == address(_legendEscrow),
            "LegendNFT: Tokens can only be edited when whole collection is in Escrow"
        );
        _;
    }

    constructor(address _accessControlAddress) ERC721("LegendNFT", "CHRON") {
        _accessControl = GlobalLegendAccessControl(_accessControlAddress);
        _totalSupplyCount = 0;
    }

    function mintBatch(
        string memory _uri,
        uint256 _amount,
        uint256 _collectionId,
        address _creator,
        address[] memory _acceptedTokens,
        uint256[] memory _basePrices,
        string memory _printType,
        uint256 _fulfillerId,
        uint256 _discount,
        uint256 _grantCollectorsOnly,
        uint256 _pubId,
        address _dynamicNFTAddress
    ) public onlyCollectionContract {
        uint256[] memory tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            _totalSupplyCount += 1;
            Token memory newToken = Token({
                tokenId: _totalSupplyCount,
                collectionId: _collectionId,
                acceptedTokens: _acceptedTokens,
                basePrices: _basePrices,
                creator: _creator,
                uri: _uri,
                isBurned: false,
                timestamp: block.timestamp,
                fulfillerId: _fulfillerId,
                printType: _printType,
                discount: _discount,
                grantCollectorsOnly: _grantCollectorsOnly,
                pubId: _pubId,
                dynamicNFTAddress: _dynamicNFTAddress
            });

            tokens[_totalSupplyCount] = newToken;
            tokenIds[i] = _totalSupplyCount;
            _safeMint(address(_legendEscrow), _totalSupplyCount);
            _legendEscrow.deposit(_totalSupplyCount, true);
        }

        emit BatchTokenMinted(address(_legendEscrow), tokenIds, _uri);
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

    function setLegendCollection(address _legendCollectionAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendCollection);
        _legendCollection = LegendCollection(_legendCollectionAddress);
        emit LegendCollectionUpdated(
            oldAddress,
            _legendCollectionAddress,
            msg.sender
        );
    }

    function setLegendEscrow(address _legendEscrowAddress) external onlyAdmin {
        address oldAddress = address(_legendEscrow);
        _legendEscrow = LegendEscrow(_legendEscrowAddress);
        emit LegendEscrowUpdated(oldAddress, _legendEscrowAddress, msg.sender);
    }

    function updateAccessControl(address _newAccessControlAddress)
        public
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return tokens[_tokenId].uri;
    }

    function getTotalSupplyCount() public view returns (uint256) {
        return _totalSupplyCount;
    }

    function getTokenCreator(uint256 _tokenId) public view returns (address) {
        return tokens[_tokenId].creator;
    }

    function getTokenAcceptedTokens(uint256 _tokenId)
        public
        view
        returns (address[] memory)
    {
        return tokens[_tokenId].acceptedTokens;
    }

    function getBasePrices(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return tokens[_tokenId].basePrices;
    }

    function getTokenCollection(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tokens[_tokenId].collectionId;
    }

    function getDiscount(uint256 _tokenId) public view returns (uint256) {
        return tokens[_tokenId].discount;
    }

    function getGrantCollectorsOnly(uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return tokens[_tokenId].grantCollectorsOnly;
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

    function getPrintType(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return tokens[_tokenId].printType;
    }

    function getDynamicNFTAddress(uint256 _tokenId)
        public
        view
        returns (address)
    {
        return tokens[_tokenId].dynamicNFTAddress;
    }

    function getFulfillerId(uint256 _tokenId) public view returns (uint256) {
        return tokens[_tokenId].fulfillerId;
    }

    function getPubId(uint256 _tokenId) public view returns (uint256) {
        return tokens[_tokenId].pubId;
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

    function setBasePrices(uint256 _tokenId, uint256[] memory _newPrices)
        public
        onlyCollectionContract
        tokensInEscrow(_tokenId)
    {
        uint256[] memory oldPrices = tokens[_tokenId].basePrices;
        tokens[_tokenId].basePrices = _newPrices;
        emit TokenBasePriceUpdated(_tokenId, oldPrices, _newPrices, msg.sender);
    }

    function setFulfillerId(uint256 _tokenId, uint256 _newFulfillerId)
        public
        onlyCollectionContract
        tokensInEscrow(_tokenId)
    {
        uint256 oldFulfillerId = tokens[_tokenId].fulfillerId;
        tokens[_tokenId].fulfillerId = _newFulfillerId;
        emit TokenFulfillerIdUpdated(
            _tokenId,
            oldFulfillerId,
            _newFulfillerId,
            msg.sender
        );
    }

    function setPrintType(uint256 _tokenId, string memory _newPrintType)
        public
        onlyCollectionContract
        tokensInEscrow(_tokenId)
    {
        string memory oldPrintType = tokens[_tokenId].printType;
        tokens[_tokenId].printType = _newPrintType;
        emit TokenPrintTypeUpdated(
            _tokenId,
            oldPrintType,
            _newPrintType,
            msg.sender
        );
    }

    function setTokenURI(uint256 _tokenId, string memory _newURI)
        public
        onlyCollectionContract
        tokensInEscrow(_tokenId)
    {
        string memory oldURI = tokens[_tokenId].uri;
        tokens[_tokenId].uri = _newURI;
        emit TokenURIUpdated(_tokenId, oldURI, _newURI, msg.sender);
    }

    function setGrantCollectorsOnly(uint256 _tokenId, bool _collectorsOnly)
        public
        onlyCollectionContract
        tokensInEscrow(_tokenId)
    {
        tokens[_tokenId].grantCollectorsOnly = _collectorsOnly;
        emit TokenGrantCollectorsOnlyUpdated(
            _tokenId,
            _collectorsOnly,
            msg.sender
        );
    }

    function setDiscount(uint256 _tokenId, uint256 _discount)
        public
        onlyCollectionContract
        tokensInEscrow(_tokenId)
    {
        tokens[_tokenId].discount = _discount;
        emit TokenDiscountUpdated(_tokenId, _discount, msg.sender);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getLegendEscrowContract() public view returns (address) {
        return address(_legendEscrow);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }
}
