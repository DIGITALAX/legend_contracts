// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendNFT.sol";
import "./GlobalLegendAccessControl.sol";
import "./LegendPayment.sol";
import "./LegendDrop.sol";
import "./LegendFactory.sol";
import "./LegendFulfillment.sol";
import "./LegendMarket.sol";

interface IDynamicNFT {
    function getDeployerAddress() external view returns (address);

    function getCollectorClaimedNFT(address) external view returns (bool);
}

interface ILegendKeeper {
    function getPostId() external view returns (uint256);
}

library MintParamsLibrary {
    struct MintParams {
        address[] acceptedTokens;
        uint256[] basePrices;
        string uri;
        string printType;
        uint256 fulfillerId;
        uint256 discount;
        bool grantCollectorsOnly;
    }
}

contract LegendCollection {
    using MintParamsLibrary for MintParamsLibrary.MintParams;

    LegendNFT private _legendNFT;
    LegendFulfillment private _legendFulfillment;
    GlobalLegendAccessControl private _accessControl;
    LegendPayment private _legendPayment;
    LegendMarket private _legendMarket;
    LegendDrop private _legendDrop;
    LegendFactory private _legendFactory;
    uint256 private _collectionSupply;
    string public symbol;
    string public name;

    struct Collection {
        uint256[] basePrices;
        uint256[] tokenIds;
        uint256 collectionId;
        uint256 amount;
        uint256 dropId;
        uint256 timestamp;
        uint256 mintedTokens;
        address[] acceptedTokens;
        address creator;
        string uri;
        bool isDeleted;
    }

    mapping(uint256 => Collection) private _collections;
    mapping(uint256 => uint256) private _fulfillerId;
    mapping(uint256 => string) private _printType;
    mapping(uint256 => uint256) private _discount;
    mapping(uint256 => bool) private _grantCollectorsOnly;
    mapping(uint256 => uint256) private _pubId;
    mapping(uint256 => address) private _dynamicNFTAddress;

    event TokensMinted(
        uint256 indexed collectionId,
        string uri,
        uint256 amountMinted,
        uint256[] tokenIdsMinted,
        address owner
    );

    event CollectionCreated(
        uint256 indexed collectionId,
        string uri,
        uint256 amount,
        address owner
    );

    event CollectionDeleted(address sender, uint256 indexed collectionId);

    event CollectionAdded(
        uint256 indexed collectionId,
        uint256 amount,
        address owner
    );

    event CollectionURIUpdated(
        uint256 indexed collectionId,
        string oldURI,
        string newURI,
        address updater
    );

    event CollectionBasePricesUpdated(
        uint256 indexed collectionId,
        uint256[] oldPrices,
        uint256[] newPrices,
        address updater
    );

    event CollectionAcceptedTokensUpdated(
        uint256 indexed collectionId,
        address[] oldAcceptedTokens,
        address[] newAcceptedTokens,
        address updater
    );

    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    event LegendNFTUpdated(
        address indexed oldLegendNFT,
        address indexed newLegendNFT,
        address updater
    );

    event LegendFulfillmentUpdated(
        address indexed oldLegendFulfillment,
        address indexed newLegendFulfillment,
        address updater
    );

    event LegendPaymentUpdated(
        address indexed oldLegendPayment,
        address indexed newLegendPayment,
        address updater
    );

    event LegendFactoryUpdated(
        address indexed oldLegendFactory,
        address indexed newLegendFactory,
        address updater
    );

    event LegendMarketUpdated(
        address indexed oldLegendMarket,
        address indexed newLegendMarket,
        address updater
    );

    event LegendDropUpdated(
        address indexed oldLegendDrop,
        address indexed newLegendDrop,
        address updater
    );

    event CollectionFulfillerIdUpdated(
        uint256 indexed collectionId,
        uint256 oldFulfillerId,
        uint256 newFulfillerId,
        address updater
    );

    event CollectionDropIdUpdated(
        uint256 indexed collectionId,
        uint256 newDropId,
        address updater
    );

    event CollectionPrintTypeUpdated(
        uint256 indexed collectionId,
        string oldPrintType,
        string newPrintType,
        address updater
    );

    event CollectionDiscountUpdated(
        uint256 indexed collectionId,
        uint256 discount,
        address updater
    );

    event CollectionGrantCollectorsOnlyUpdated(
        uint256 indexed collectionId,
        bool grantCollectorOnly,
        address updater
    );

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyCreator(uint256 _collectionId) {
        require(
            msg.sender == _collections[_collectionId].creator,
            "LegendCollection: Only the creator can edit this collection"
        );
        _;
    }

    modifier onlyMarket() {
        require(
            msg.sender == address(_legendMarket),
            "LegendCollection: Only the market contract can call purchase"
        );
        _;
    }

    modifier onlyGrantPublishers(
        address _functionCallerAddress,
        string memory _grantName
    ) {
        require(
            _legendFactory.getGrantContracts(
                _functionCallerAddress,
                _grantName
            )[2] !=
                address(0) &&
                IDynamicNFT(
                    _legendFactory.getGrantContracts(
                        _functionCallerAddress,
                        _grantName
                    )[2]
                ).getDeployerAddress() ==
                _functionCallerAddress,
            "LegendCollection: Only grant publishers can make collections for their grants."
        );
        _;
    }

    constructor(
        address _legendNFTAddress,
        address _accessControlAddress,
        address _legendPaymentAddress,
        address _legendFactoryAddress,
        string memory _symbol,
        string memory _name
    ) {
        _legendNFT = LegendNFT(_legendNFTAddress);
        _accessControl = GlobalLegendAccessControl(_accessControlAddress);
        _legendPayment = LegendPayment(_legendPaymentAddress);
        _legendFactory = LegendFactory(_legendFactoryAddress);
        _collectionSupply = 0;
        symbol = _symbol;
        name = _name;
    }

    function createCollection(
        uint256 _amount,
        MintParamsLibrary.MintParams memory params,
        string memory _grantName,
        bool _noLimit
    ) external onlyGrantPublishers(msg.sender, _grantName) {
        address _creator = msg.sender;

        require(
            params.basePrices.length == params.acceptedTokens.length,
            "LegendCollection: Invalid input"
        );
        require(
            _accessControl.isAdmin(_creator) ||
                _accessControl.isWriter(_creator),
            "LegendCollection: Only admin or writer can perform this action"
        );
        require(
            _legendFulfillment.getFulfillerAddress(params.fulfillerId) !=
                address(0),
            "LegendFulfillment: FulfillerId does not exist."
        );
        for (uint256 i = 0; i < params.acceptedTokens.length; i++) {
            require(
                _legendPayment.checkIfAddressVerified(params.acceptedTokens[i]),
                "LegendCollection: Payment Token is Not Verified"
            );
        }

        _collectionSupply++;

        uint256 _pubIdValue = ILegendKeeper(
            _legendFactory.getGrantContracts(_creator, _grantName)[0]
        ).getPostId();
        address _dynamicNFTAddressValue = _legendFactory.getGrantContracts(
            _creator,
            _grantName
        )[2];

        if (_noLimit) {
            _amount = type(uint256).max;
        }

        _createNewCollection(params, _amount, _creator);

        _setMappings(params, _pubIdValue, _dynamicNFTAddressValue);

        emit CollectionCreated(
            _collectionSupply,
            params.uri,
            _amount,
            _creator
        );
    }

    function addToExistingCollection(uint256 _collectionId, uint256 _amount)
        external
    {
        address _creator = msg.sender;
        require(
            _collections[_collectionId].amount == type(uint256).max,
            "LegendCollection: Collection cannot be added to."
        );

        require(
            !_collections[_collectionId].isDeleted,
            "LegendCollection: This collection has been deleted"
        );

        require(
            _accessControl.isAdmin(_creator) ||
                _accessControl.isWriter(_creator),
            "LegendCollection: Only admin or writer can perform this action"
        );
        require(
            _collections[_collectionId].creator == _creator,
            "LegendCollection: Only the owner of a collection can add to it."
        );

        _collections[_collectionId].amount += _amount;

        emit CollectionAdded(_collectionId, _amount, _creator);
    }

    function _setMappings(
        MintParamsLibrary.MintParams memory params,
        uint256 _pubIdValue,
        address _dynamicNFTAddressValue
    ) private {
        _printType[_collectionSupply] = params.printType;
        _fulfillerId[_collectionSupply] = params.fulfillerId;
        _discount[_collectionSupply] = params.discount;
        _grantCollectorsOnly[_collectionSupply] = params.grantCollectorsOnly;
        _pubId[_collectionSupply] = _pubIdValue;
        _dynamicNFTAddress[_collectionSupply] = _dynamicNFTAddressValue;
    }

    function _createNewCollection(
        MintParamsLibrary.MintParams memory params,
        uint256 _amount,
        address _creatorAddress
    ) private {
        Collection memory newCollection = Collection({
            collectionId: _collectionSupply,
            acceptedTokens: params.acceptedTokens,
            basePrices: params.basePrices,
            tokenIds: new uint256[](0),
            amount: _amount,
            mintedTokens: 0,
            creator: _creatorAddress,
            uri: params.uri,
            isDeleted: false,
            timestamp: block.timestamp,
            dropId: 0
        });

        _collections[_collectionSupply] = newCollection;
    }

    function _mintNFT(
        Collection memory _collection,
        uint256 _pubIdValue,
        uint256 _amount,
        address _dynamicNFTAddressValue,
        address _creatorAddress,
        address _purchaserAddress
    ) private {
        MintParamsLibrary.MintParams memory paramsNFT = MintParamsLibrary
            .MintParams({
                acceptedTokens: _collection.acceptedTokens,
                basePrices: _collection.basePrices,
                uri: _collection.uri,
                printType: _printType[_collection.collectionId],
                fulfillerId: _fulfillerId[_collection.collectionId],
                discount: _discount[_collection.collectionId],
                grantCollectorsOnly: _grantCollectorsOnly[
                    _collection.collectionId
                ]
            });

        _legendNFT.mintBatch(
            paramsNFT,
            _amount,
            _pubIdValue,
            _collectionSupply,
            _dynamicNFTAddressValue,
            _creatorAddress,
            _purchaserAddress
        );
    }

    function purchaseAndMintToken(
        uint256[] memory _collectionIds,
        uint256[] memory _amounts,
        address _purchaserAddress
    ) external onlyMarket {
        require(
            _collectionIds.length == _amounts.length,
            "LegendCollection: Input arrays must be of equal length"
        );

        for (uint256 c = 0; c < _collectionIds.length; c++) {
            Collection storage collection = _collections[_collectionIds[c]];

            require(
                !collection.isDeleted,
                "LegendCollection: This collection has been deleted."
            );

            require(
                collection.amount == type(uint256).max ||
                    collection.mintedTokens + _amounts[c] <= collection.amount,
                "LegendCollection: Cannot mint more than collection amount"
            );

            uint256 initialSupply = _legendNFT.getTotalSupplyCount();

            for (uint256 i = 0; i < _amounts[c]; i++) {
                _mintNFT(
                    _collections[_collectionIds[c]],
                    _pubId[_collectionIds[c]],
                    _amounts[c],
                    _dynamicNFTAddress[_collectionIds[c]],
                    collection.creator,
                    _purchaserAddress
                );
            }

            uint256 finalSupply = _legendNFT.getTotalSupplyCount();
            uint256[] memory emissionArray = new uint256[](_amounts[c]);

            for (uint256 i = initialSupply + 1; i <= finalSupply; i++) {
                collection.tokenIds.push(i);
                emissionArray[i - (initialSupply + 1)] = i;
                collection.mintedTokens++;
            }

            emit TokensMinted(
                collection.collectionId,
                collection.uri,
                _amounts[c],
                emissionArray,
                collection.creator
            );
        }
    }

    function deleteCollection(uint256 _collectionId)
        public
        onlyCreator(_collectionId)
    {
        require(
            !_collections[_collectionId].isDeleted,
            "LegendCollection: This collection has already been deleted."
        );

        Collection storage collection = _collections[_collectionId];

        if (getCollectionDropId(_collectionId) != 0) {
            _legendDrop.removeCollectionFromDrop(_collectionId);
        }

        if (collection.mintedTokens == 0) {
            delete _collections[_collectionId];
        } else {
            collection.amount = collection.mintedTokens;
        }
        collection.isDeleted = true;

        emit CollectionDeleted(msg.sender, _collectionId);
    }

    function updateAccessControl(address _newAccessControlAddress)
        external
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

    function updateLegendNFT(address _newLegendNFTAddress) external onlyAdmin {
        address oldAddress = address(_legendNFT);
        _legendNFT = LegendNFT(_newLegendNFTAddress);
        emit LegendNFTUpdated(oldAddress, _newLegendNFTAddress, msg.sender);
    }

    function updateLegendPayment(address _newLegendPaymentAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendPayment);
        _legendPayment = LegendPayment(_newLegendPaymentAddress);
        emit LegendPaymentUpdated(
            oldAddress,
            _newLegendPaymentAddress,
            msg.sender
        );
    }

    function updateLegendFactory(address _newLegendFactoryAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendFactory);
        _legendFactory = LegendFactory(_newLegendFactoryAddress);
        emit LegendFactoryUpdated(
            oldAddress,
            _newLegendFactoryAddress,
            msg.sender
        );
    }

    function setLegendMarket(address _newLegendMarketAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendMarket);
        _legendMarket = LegendMarket(_newLegendMarketAddress);
        emit LegendMarketUpdated(
            oldAddress,
            _newLegendMarketAddress,
            msg.sender
        );
    }

    function setLegendDrop(address _newLegendDropAddress) external onlyAdmin {
        address oldAddress = address(_legendDrop);
        _legendDrop = LegendDrop(_newLegendDropAddress);
        emit LegendDropUpdated(oldAddress, _newLegendDropAddress, msg.sender);
    }

    function setLegendFulfillment(address _newLegendFulfillmentAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendFulfillment);
        _legendFulfillment = LegendFulfillment(_newLegendFulfillmentAddress);
        emit LegendFulfillmentUpdated(
            oldAddress,
            _newLegendFulfillmentAddress,
            msg.sender
        );
    }

    function getCollectionCreator(uint256 _collectionId)
        public
        view
        returns (address)
    {
        return _collections[_collectionId].creator;
    }

    function getCollectionURI(uint256 _collectionId)
        public
        view
        returns (string memory)
    {
        return _collections[_collectionId].uri;
    }

    function getCollectionAmount(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _collections[_collectionId].amount;
    }

    function getCollectionAcceptedTokens(uint256 _collectionId)
        public
        view
        returns (address[] memory)
    {
        return _collections[_collectionId].acceptedTokens;
    }

    function getCollectionBasePrices(uint256 _collectionId)
        public
        view
        returns (uint256[] memory)
    {
        return _collections[_collectionId].basePrices;
    }

    function getCollectionIsDeleted(uint256 _collectionId)
        public
        view
        returns (bool)
    {
        return _collections[_collectionId].isDeleted;
    }

    function getCollectionTimestamp(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _collections[_collectionId].timestamp;
    }

    function getCollectionDropId(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _collections[_collectionId].dropId;
    }

    function getCollectionFulfillerId(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _fulfillerId[_collectionId];
    }

    function getCollectionPrintType(uint256 _collectionId)
        public
        view
        returns (string memory)
    {
        return _printType[_collectionId];
    }

    function getCollectionTokenIds(uint256 _collectionId)
        public
        view
        returns (uint256[] memory)
    {
        return _collections[_collectionId].tokenIds;
    }

    function getCollectionDiscount(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _discount[_collectionId];
    }

    function getCollectionDynamicNFTAddress(uint256 _collectionId)
        public
        view
        returns (address)
    {
        return _dynamicNFTAddress[_collectionId];
    }

    function getCollectionTokensMinted(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _collections[_collectionId].mintedTokens;
    }

    function getCollectionPubId(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _pubId[_collectionId];
    }

    function getCollectionGrantCollectorsOnly(uint256 _collectionId)
        public
        view
        returns (bool)
    {
        return _grantCollectorsOnly[_collectionId];
    }

    function setCollectionPrintType(
        string memory _newPrintType,
        uint256 _collectionId
    ) external onlyCreator(_collectionId) {
        require(
            !_collections[_collectionId].isDeleted,
            "LegendCollection: This collection has been deleted."
        );

        string memory oldPrintType = _printType[_collectionId];
        _printType[_collectionId] = _newPrintType;
        emit CollectionPrintTypeUpdated(
            _collectionId,
            oldPrintType,
            _newPrintType,
            msg.sender
        );
    }

    function setCollectionFulfillerId(
        uint256 _newFulfillerId,
        uint256 _collectionId
    ) external onlyCreator(_collectionId) {
        require(
            _legendFulfillment.getFulfillerAddress(_newFulfillerId) !=
                address(0),
            "LegendFulfillment: FulfillerId does not exist."
        );

        require(
            !_collections[_collectionId].isDeleted,
            "LegendCollection: This collection has been deleted."
        );
        uint256 oldFufillerId = _fulfillerId[_collectionId];
        _fulfillerId[_collectionId] = _newFulfillerId;
        emit CollectionFulfillerIdUpdated(
            _collectionId,
            oldFufillerId,
            _newFulfillerId,
            msg.sender
        );
    }

    function setCollectionURI(string memory _newURI, uint256 _collectionId)
        external
        onlyCreator(_collectionId)
    {
        require(
            !_collections[_collectionId].isDeleted,
            "LegendCollection: This collection has been deleted."
        );
        string memory oldURI = _collections[_collectionId].uri;
        _collections[_collectionId].uri = _newURI;
        emit CollectionURIUpdated(_collectionId, oldURI, _newURI, msg.sender);
    }

    function setCollectionDropId(uint256 _dropId, uint256 _collectionId)
        external
    {
        require(
            msg.sender == address(_legendDrop) ||
                msg.sender == _collections[_collectionId].creator,
            "LegendCollection: Only the collection creator or drop contract can update."
        );
        _collections[_collectionId].dropId = _dropId;
        emit CollectionDropIdUpdated(_collectionId, _dropId, msg.sender);
    }

    function setCollectionDiscount(uint256 _newDiscount, uint256 _collectionId)
        external
        onlyCreator(_collectionId)
    {
        require(
            !_collections[_collectionId].isDeleted,
            "LegendCollection: This collection has been deleted."
        );
        _discount[_collectionId] = _newDiscount;
        emit CollectionDiscountUpdated(_collectionId, _newDiscount, msg.sender);
    }

    function setCollectionGrantCollectorsOnly(
        bool _collectorsOnly,
        uint256 _collectionId
    ) external onlyCreator(_collectionId) {
        require(
            !_collections[_collectionId].isDeleted,
            "LegendCollection: This collection has been deleted."
        );
        _grantCollectorsOnly[_collectionId] = _collectorsOnly;
        emit CollectionGrantCollectorsOnlyUpdated(
            _collectionId,
            _collectorsOnly,
            msg.sender
        );
    }

    function setCollectionBasePrices(
        uint256 _collectionId,
        uint256[] memory _newPrices
    ) external onlyCreator(_collectionId) {
        require(
            !_collections[_collectionId].isDeleted,
            "LegendCollection: This collection has been deleted."
        );
        uint256[] memory oldPrices = _collections[_collectionId].basePrices;
        _collections[_collectionId].basePrices = _newPrices;
        emit CollectionBasePricesUpdated(
            _collectionId,
            oldPrices,
            _newPrices,
            msg.sender
        );
    }

    function setCollectionAcceptedTokens(
        uint256 _collectionId,
        address[] memory _newAcceptedTokens
    ) external onlyCreator(_collectionId) {
        require(
            !_collections[_collectionId].isDeleted,
            "LegendCollection: This collection has been deleted."
        );
        address[] memory oldTokens = _collections[_collectionId].acceptedTokens;
        _collections[_collectionId].acceptedTokens = _newAcceptedTokens;
        emit CollectionAcceptedTokensUpdated(
            _collectionId,
            oldTokens,
            _newAcceptedTokens,
            msg.sender
        );
    }

    function getCollectionSupply() public view returns (uint256) {
        return _collectionSupply;
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getLegendPaymentContract() public view returns (address) {
        return address(_legendPayment);
    }

    function getLegendNFTContract() public view returns (address) {
        return address(_legendNFT);
    }

    function getLegendFactoryContract() public view returns (address) {
        return address(_legendFactory);
    }

    function getLegendMarketContract() public view returns (address) {
        return address(_legendMarket);
    }

    function getLegendFulfillmentContract() public view returns (address) {
        return address(_legendFulfillment);
    }

    function getLegendDropContract() public view returns (address) {
        return address(_legendDrop);
    }
}
