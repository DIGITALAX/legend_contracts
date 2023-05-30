// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendNFT.sol";
import "./GlobalLegendAccessControl.sol";
import "./LegendPayment.sol";
import "./LegendEscrow.sol";
import "./LegendDrop.sol";
import "./LegendFactory.sol";

interface IDynamicNFT {
    function getDeployerAddress() external view returns (address);
    function getCollectorClaimedNFT(address) external view returns (bool);
}

interface ILegendKeeper {
    function getPostId() external view returns (uint256);
}

contract LegendCollection {
    LegendNFT private _legendNFT;
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
        uint256 fulfillerId;
        address[] acceptedTokens;
        address creator;
        address dynamicNFTAddress;
        string uri;
        string printType;
        bool isBurned;
        uint256 discount;
        uint256 pubId;
        bool grantCollectorsOnly;
    }

    mapping(uint256 => Collection) private _collections;

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
        string oldFulfillerId,
        string newFulfillerId,
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
            "AccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyCreator(uint256 _collectionId) {
        require(
            msg.sender == _collections[_collectionId].creator,
            "ChromadinCollection: Only the creator can edit this collection"
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
        string memory _uri,
        uint256 _amount,
        address[] memory _acceptedTokens,
        uint256[] memory _basePrices,
        string memory _printType,
        uint256 _fulfillerId,
        uint256 _discount,
        bool _grantCollectorsOnly,
        string memory _grantName
    ) external {
        // make sure only the grant publisher can mint for their grant
        require(
            IDynamicNFT(
                _legendFactory.getGrantContracts(msg.sender, _grantName)[2]
            ).getDeployerAddress() == msg.sender,
            "LegendCollection: Only grant publishers can make collections for their grants."
        );
        require(
            _basePrices.length == _acceptedTokens.length,
            "LegendCollection: Invalid input"
        );
        require(
            _accessControl.isAdmin(msg.sender) ||
                _accessControl.isWriter(msg.sender),
            "LegendCollection: Only admin or writer can perform this action"
        );
        for (uint256 i = 0; i < _acceptedTokens.length; i++) {
            require(
                _legendPayment.checkIfAddressVerified(_acceptedTokens[i]),
                "LegendCollection: Payment Token is Not Verified"
            );
        }

        _collectionSupply++;

        uint256[] memory tokenIds = new uint256[](_amount);

        for (uint256 i = 0; i < _amount; i++) {
            tokenIds[i] = _legendNFT.getTotalSupplyCount() + i + 1;
        }

        uint256 _pubId = ILegendKeeper(
            _legendFactory.getGrantContracts(msg.sender, _grantName)[0]
        ).getPostId();
        address _dynamicNFTAddress = _legendFactory.getGrantContracts(
            msg.sender,
            _grantName
        )[2];

        Collection memory newCollection = Collection({
            collectionId: _collectionSupply,
            acceptedTokens: _acceptedTokens,
            basePrices: _basePrices,
            tokenIds: tokenIds,
            amount: _amount,
            creator: msg.sender,
            uri: _uri,
            isBurned: false,
            timestamp: block.timestamp,
            printType: _printType,
            fulfillerId: _fulfillerId,
            dropId: 0,
            discount: _discount,
            grantCollectorsOnly: _grantCollectorsOnly,
            pubId: _pubId,
            dynamicNFTAddress: _dynamicNFTAddress
        });

        _collections[_collectionSupply] = newCollection;

        _legendNFT.mintBatch(
            _uri,
            _amount,
            _collectionSupply,
            msg.sender,
            _acceptedTokens,
            _basePrices,
            _printType,
            _fulfillerId,
            _discount,
            _grantCollectorsOnly,
            _pubId,
            _dynamicNFTAddress
        );

        emit CollectionMinted(_collectionSupply, _uri, _amount, msg.sender);
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
        return _collections[_collectionId].fulfillerId;
    }

    function getCollectionPrintType(uint256 _collectionId)
        public
        view
        returns (string memory)
    {
        return _collections[_collectionId].printType;
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
        return _collections[_collectionId].discount;
    }

    function getDynamicNFTAddress(uint256 _collectionId)
        public
        view
        returns (address)
    {
        return _collections[_collectionId].dynamicNFTAddress;
    }

    function getPubId(uint256 _collectionId) public view returns (uint256) {
        return _collections[_collectionId].pubId;
    }

    function getCollectionGrantCollectorsOnly(uint256 _collectionId)
        public
        view
        returns (bool)
    {
        return _collections[_collectionId].grantCollectorsOnly;
    }

    function setCollectionPrintType(
        string memory _newPrintType,
        uint256 _collectionId
    ) external onlyCreator(_collectionId) {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                _legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow),
                "LegendCollection: The entire collection must be owned by Escrow to update"
            );
            _legendNFT.setPrintType(tokenIds[i], _newPrintType);
        }
        string memory oldPrintType = _collections[_collectionId].printType;
        _collections[_collectionId].printType = _newPrintType;
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
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                _legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow),
                "LegendCollection: The entire collection must be owned by Escrow to update"
            );
            _legendNFT.setFufillerId(tokenIds[i], _newFulfillerId);
        }
        string memory oldFufillerId = _collections[_collectionId].fulfillerId;
        _collections[_collectionId].fulfillerId = _newFulfillerId;
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
        onlyCreator(_collectionId)
    {
        _collections[_collectionId].dropId = _dropId;
        emit CollectionDropIdUpdated(_collectionId, _dropId, msg.sender);
    }

    function setCollectionDiscount(uint256 _discount, uint256 _collectionId)
        external
        onlyCreator(_collectionId)
    {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _legendNFT.setDiscount(tokenIds[i], _discount);
        }
        _collections[_collectionId].discount = _discount;
        emit CollectionDiscountUpdated(_collectionId, _discount, msg.sender);
    }

    function setCollectionGrantCollectorsOnly(
        bool _collectorsOnly,
        uint256 _collectionId
    ) external onlyCreator(_collectionId) {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _legendNFT.setGrantCollectorsOnly(tokenIds[i], _collectorsOnly);
        }
        _collections[_collectionId].grantCollectorsOnly = _collectorsOnly;
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
            require(
                _legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow),
                "LegendCollection: The entire collection must be owned by Escrow to update"
            );
            _legendNFT.setBasePrices(tokenIds[i], _newPrices);
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
            require(
                _legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow),
                "LegendCollection: The entire collection must be owned by Escrow to update"
            );
            _legendNFT.setTokenAcceptedTokens(tokenIds[i], _newAcceptedTokens);
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
}
