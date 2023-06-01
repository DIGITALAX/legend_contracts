// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendNFT.sol";
import "./GlobalLegendAccessControl.sol";
import "./LegendPayment.sol";
import "./LegendEscrow.sol";
import "./LegendDrop.sol";
import "./LegendFactory.sol";
import "./LegendFulfillment.sol";

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
    LegendEscrow private _legendEscrow;
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
        address[] acceptedTokens;
        address creator;
        string uri;
        bool isBurned;
    }

    mapping(uint256 => Collection) private _collections;
    mapping(uint256 => uint256) private _fulfillerId;
    mapping(uint256 => string) private _printType;
    mapping(uint256 => uint256) private _discount;
    mapping(uint256 => bool) private _grantCollectorsOnly;
    mapping(uint256 => uint256) private _pubId;
    mapping(uint256 => address) private _dynamicNFTAddress;

    event CollectionMinted(
        uint256 indexed collectionId,
        string uri,
        uint256 amount,
        address owner
    );

    event CollectionBurned(
        address indexed burner,
        uint256 indexed collectionId
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

    event LegendEscrowUpdated(
        address indexed oldLegendEscrow,
        address indexed newLegendEscrow,
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

    function mintCollection(
        uint256 _amount,
        MintParamsLibrary.MintParams memory params,
        string memory _grantName
    ) external onlyGrantPublishers(msg.sender, _grantName) {
        require(
            params.basePrices.length == params.acceptedTokens.length,
            "LegendCollection: Invalid input"
        );
        require(
            _accessControl.isAdmin(msg.sender) ||
                _accessControl.isWriter(msg.sender),
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

        uint256[] memory tokenIds = new uint256[](_amount);

        for (uint256 i = 0; i < _amount; i++) {
            tokenIds[i] = _legendNFT.getTotalSupplyCount() + i + 1;
        }

        uint256 _pubIdValue = ILegendKeeper(
            _legendFactory.getGrantContracts(msg.sender, _grantName)[0]
        ).getPostId();
        address _dynamicNFTAddressValue = _legendFactory.getGrantContracts(
            msg.sender,
            _grantName
        )[2];

        _createNewCollection(params, _amount, tokenIds, msg.sender);

        _setMappings(params, _pubIdValue, _dynamicNFTAddressValue);

        _mintNFT(
            params,
            _pubIdValue,
            _amount,
            _dynamicNFTAddressValue,
            msg.sender
        );

        emit CollectionMinted(
            _collectionSupply,
            params.uri,
            _amount,
            msg.sender
        );
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
        uint256[] memory tokenIds,
        address _creatorAddress
    ) private {
        Collection memory newCollection = Collection({
            collectionId: _collectionSupply,
            acceptedTokens: params.acceptedTokens,
            basePrices: params.basePrices,
            tokenIds: tokenIds,
            amount: _amount,
            creator: _creatorAddress,
            uri: params.uri,
            isBurned: false,
            timestamp: block.timestamp,
            dropId: 0
        });

        _collections[_collectionSupply] = newCollection;
    }

    function _mintNFT(
        MintParamsLibrary.MintParams memory params,
        uint256 _pubIdValue,
        uint256 _amount,
        address _dynamicNFTAddressValue,
        address _creatorAddress
    ) private {
        MintParamsLibrary.MintParams memory paramsNFT = MintParamsLibrary
            .MintParams({
                acceptedTokens: params.acceptedTokens,
                basePrices: params.basePrices,
                uri: params.uri,
                printType: params.printType,
                fulfillerId: params.fulfillerId,
                discount: params.discount,
                grantCollectorsOnly: params.grantCollectorsOnly
            });

        _legendNFT.mintBatch(
            paramsNFT,
            _amount,
            _pubIdValue,
            _collectionSupply,
            _dynamicNFTAddressValue,
            _creatorAddress
        );
    }

    function burnCollection(uint256 _collectionId)
        external
        onlyCreator(_collectionId)
    {
        require(
            !_collections[_collectionId].isBurned,
            "LegendCollection: This collection has already been burned"
        );

        if (getCollectionDropId(_collectionId) != 0) {
            _legendDrop.removeCollectionFromDrop(_collectionId);
        }

        for (
            uint256 i = 0;
            i < _collections[_collectionId].tokenIds.length;
            i++
        ) {
            if (
                address(_legendEscrow) ==
                _legendNFT.ownerOf(_collections[_collectionId].tokenIds[i])
            ) {
                _legendEscrow.release(
                    _collections[_collectionId].tokenIds[i],
                    true,
                    address(0)
                );
            }
        }

        _collections[_collectionId].isBurned = true;
        emit CollectionBurned(msg.sender, _collectionId);
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

    function setLegendEscrow(address _newLegendEscrowAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendEscrow);
        _legendEscrow = LegendEscrow(_newLegendEscrowAddress);
        emit LegendEscrowUpdated(
            oldAddress,
            _newLegendEscrowAddress,
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

    function getCollectionIsBurned(uint256 _collectionId)
        public
        view
        returns (bool)
    {
        return _collections[_collectionId].isBurned;
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
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setPrintType(tokenIds[i], _newPrintType);
            }
        }
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
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setFulfillerId(tokenIds[i], _newFulfillerId);
            }
        }
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
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                _legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow),
                "LegendCollection: The entire collection must be owned by Escrow to update"
            );
            _legendNFT.setTokenURI(tokenIds[i], _newURI);
        }
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
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setDiscount(tokenIds[i], _newDiscount);
            }
        }
        _discount[_collectionId] = _newDiscount;
        emit CollectionDiscountUpdated(_collectionId, _newDiscount, msg.sender);
    }

    function setCollectionGrantCollectorsOnly(
        bool _collectorsOnly,
        uint256 _collectionId
    ) external onlyCreator(_collectionId) {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setGrantCollectorsOnly(tokenIds[i], _collectorsOnly);
            }
        }
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
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setBasePrices(tokenIds[i], _newPrices);
            }
        }
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
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setTokenAcceptedTokens(
                    tokenIds[i],
                    _newAcceptedTokens
                );
            }
        }
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

    function getLegendEscrowContract() public view returns (address) {
        return address(_legendEscrow);
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

    function getLegendFulfillmentContract() public view returns (address) {
        return address(_legendFulfillment);
    }

    function getLegendDropContract() public view returns (address) {
        return address(_legendDrop);
    }
}
