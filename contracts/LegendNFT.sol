// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendCollection.sol";
import "./GlobalLegendAccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract LegendNFT is ERC721Enumerable {
    using MintParamsLibrary for MintParamsLibrary.MintParams;

    GlobalLegendAccessControl private _accessControl;
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
    }

    mapping(uint256 => Token) private _tokens;
    mapping(uint256 => uint256) private _fulfillerId;
    mapping(uint256 => string) private _printType;
    mapping(uint256 => uint256) private _discount;
    mapping(uint256 => bool) private _grantCollectorsOnly;
    mapping(uint256 => uint256) private _pubId;
    mapping(uint256 => address) private _dynamicNFTAddress;

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
            "GlobalLegendAccessControl: Only admin can perform this action"
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

    constructor(address _accessControlAddress) ERC721("LegendNFT", "CHRON") {
        _accessControl = GlobalLegendAccessControl(_accessControlAddress);
        _totalSupplyCount = 0;
    }

    function mintBatch(
        MintParamsLibrary.MintParams memory params,
        uint256 _amount,
        uint256 _pubIdValue,
        uint256 _collectionId,
        address _dynamicNFTAddressValue,
        address _creatorAddress,
        address _purchaserAddress
    ) public onlyCollectionContract {
        require(
            params.discount < 100,
            "LegendMarket: Discount cannot exceed 100."
        );
        uint256[] memory tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            _totalSupplyCount += 1;
            _mintToken(params, _collectionId, _creatorAddress);
            _setMappings(params, _pubIdValue, _dynamicNFTAddressValue);

            tokenIds[i] = _totalSupplyCount;
            _safeMint(_purchaserAddress, _totalSupplyCount);
        }

        emit BatchTokenMinted(_purchaserAddress, tokenIds, params.uri);
    }

    function _setMappings(
        MintParamsLibrary.MintParams memory params,
        uint256 _pubIdValue,
        address _dynamicNFTAddressValue
    ) private {
        _fulfillerId[_totalSupplyCount] = params.fulfillerId;
        _printType[_totalSupplyCount] = params.printType;
        _discount[_totalSupplyCount] = params.discount;
        _grantCollectorsOnly[_totalSupplyCount] = params.grantCollectorsOnly;
        _pubId[_totalSupplyCount] = _pubIdValue;
        _dynamicNFTAddress[_totalSupplyCount] = _dynamicNFTAddressValue;
    }

    function _mintToken(
        MintParamsLibrary.MintParams memory params,
        uint256 _collectionId,
        address _creatorAddress
    ) private {
        Token memory newToken = Token({
            tokenId: _totalSupplyCount,
            collectionId: _collectionId,
            acceptedTokens: params.acceptedTokens,
            basePrices: params.basePrices,
            creator: _creatorAddress,
            uri: params.uri,
            isBurned: false,
            timestamp: block.timestamp
        });

        _tokens[_totalSupplyCount] = newToken;
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
        _tokens[_tokenId].isBurned = true;
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
        return _tokens[_tokenId].uri;
    }

    function getTotalSupplyCount() public view returns (uint256) {
        return _totalSupplyCount;
    }

    function getTokenCreator(uint256 _tokenId) public view returns (address) {
        return _tokens[_tokenId].creator;
    }

    function getTokenAcceptedTokens(uint256 _tokenId)
        public
        view
        returns (address[] memory)
    {
        return _tokens[_tokenId].acceptedTokens;
    }

    function getTokenBasePrices(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return _tokens[_tokenId].basePrices;
    }

    function getTokenCollection(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return _tokens[_tokenId].collectionId;
    }

    function getTokenDiscount(uint256 _tokenId) public view returns (uint256) {
        return _discount[_tokenId];
    }

    function getTokenGrantCollectorsOnly(uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return _grantCollectorsOnly[_tokenId];
    }

    function getTokenIsBurned(uint256 _tokenId) public view returns (bool) {
        return _tokens[_tokenId].isBurned;
    }

    function getTokenTimestamp(uint256 _tokenId) public view returns (uint256) {
        return _tokens[_tokenId].timestamp;
    }

    function getTokenId(uint256 _tokenId) public view returns (uint256) {
        return _tokens[_tokenId].tokenId;
    }

    function getTokenPrintType(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return _printType[_tokenId];
    }

    function getTokenDynamicNFTAddress(uint256 _tokenId)
        public
        view
        returns (address)
    {
        return _dynamicNFTAddress[_tokenId];
    }

    function getTokenFulfillerId(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return _fulfillerId[_tokenId];
    }

    function getTokenPubId(uint256 _tokenId) public view returns (uint256) {
        return _pubId[_tokenId];
    }

    function setTokenAcceptedTokens(
        uint256 _tokenId,
        address[] memory _newAcceptedTokens
    ) public onlyCollectionContract {
        address[] memory oldTokens = _tokens[_tokenId].acceptedTokens;
        _tokens[_tokenId].acceptedTokens = _newAcceptedTokens;
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
    {
        uint256[] memory oldPrices = _tokens[_tokenId].basePrices;
        _tokens[_tokenId].basePrices = _newPrices;
        emit TokenBasePriceUpdated(_tokenId, oldPrices, _newPrices, msg.sender);
    }

    function setFulfillerId(uint256 _tokenId, uint256 _newFulfillerId)
        public
        onlyCollectionContract
    {
        uint256 oldFulfillerId = _fulfillerId[_tokenId];
        _fulfillerId[_tokenId] = _newFulfillerId;
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
    {
        string memory oldPrintType = _printType[_tokenId];
        _printType[_tokenId] = _newPrintType;
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
    {
        string memory oldURI = _tokens[_tokenId].uri;
        _tokens[_tokenId].uri = _newURI;
        emit TokenURIUpdated(_tokenId, oldURI, _newURI, msg.sender);
    }

    function setGrantCollectorsOnly(uint256 _tokenId, bool _collectorsOnly)
        public
        onlyCollectionContract
    {
        _grantCollectorsOnly[_tokenId] = _collectorsOnly;
        emit TokenGrantCollectorsOnlyUpdated(
            _tokenId,
            _collectorsOnly,
            msg.sender
        );
    }

    function setDiscount(uint256 _tokenId, uint256 _newDiscount)
        public
        onlyCollectionContract
    {
        require(
            _newDiscount < 100,
            "LegendMarket: Discount cannot exceed 100."
        );
        _discount[_tokenId] = _newDiscount;
        emit TokenDiscountUpdated(_tokenId, _newDiscount, msg.sender);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }
}
