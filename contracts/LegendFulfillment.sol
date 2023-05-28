// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./LegendNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LegendFulfillment {
    LegendNFT public legendNFT;
    AccessControl public accessControl;
    LegendCollection public legendCollection;
    uint256 public orderSupply;
    string public symbol;
    string public name;
    uint256[] public fulfillmentOracle;

    struct Order {
        uint256 orderId;
        uint256 tokenId;
        string uri;
        address buyer;
        address chosenAddress;
        uint256 totalPrice;
        uint256 timestamp;
        string status;
        bool isFulfilled;
        uint256 fulfillerId;
    }

    struct Fulfiller {
        uint256 fulfillerId;
        uint256 fulfillerPercent;
        address fulfillerAddress;
    }

    struct FulfillmentPrices {
        uint256[] apparelPrices;
        uint256[] stickerPrices;
        uint256[] posterPrices;
    }

    mapping(uint256 => Order) private orders;
    mapping(uint256 => Fulfiller) private fulfillers;
    mapping(uint256 => FulfillmentPrices) private fulfillToCollection;

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

    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
        address updater
    );

    event OrderCreated(
        uint256 indexed orderId,
        address buyer,
        uint256 totalPrice
    );

    event FulfillerAddressUpdated(
        uint256 indexed fulfillerId,
        address newFulfillerAddress
    );

    event FulfillerPercentUpdated(
        uint256 indexed fulfillerId,
        uint256 newFulfillerPercent
    );

    event CollectionApparelPricesUpdated(
        uint256 indexed collectionId,
        uint256[] oldApparelPrices,
        uint256[] newApparelPrices,
        address updater
    );

    event CollectionStickerPricesUpdated(
        uint256 indexed collectionId,
        uint256[] oldStickerPrices,
        uint256[] newStickerPrices,
        address updater
    );

    event CollectionPosterPricesUpdated(
        uint256 indexed collectionId,
        uint256[] oldPosterPrices,
        uint256[] newPosterPrices,
        address updater
    );

    modifier onlyAdmin() {
        require(
            accessControl.isAdmin(msg.sender),
            "AccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier ownNFT(uint256 _tokenId) {
        require(
            msg.sender == legendNFT.ownerOf(_tokenId),
            "LegendFulfillment: Must own token"
        );
        _;
    }

    modifier onlyCreator(uint256 _collectionId) {
        require(
            msg.sender ==
                legendCollection.getCollectionCreator(_collectionId),
            "LegendCollection: Only the creator can edit this collection"
        );
        _;
    }

    constructor(
        address _accessControlContract,
        address _NFTContract,
        address _collectionContract,
        string memory _symbol,
        string memory _name
    ) {
        accessControl = AccessControl(_accessControlContract);
        legendNFT = LegendNFT(_NFTContract);
        legendCollection = LegendCollection(_collectionContract);
        orderSupply = 0;
        symbol = _symbol;
        name = _name;
    }

    function fulfillItems(
        uint256 _tokenId,
        uint256[] memory _apparelItems,
        uint256[] memory _stickerItems,
        uint256[] memory _posterItems,
        address _chosenTokenAddress,
        string memory _uri,
        uint256 _fulfillerId
    ) external ownNFT(_tokenId) {
        require(
            legendNFT.getTokenFulfilled(_tokenId),
            "LegendFulfillment: Token is not set for fulfillment"
        );

        address[] memory acceptedTokens = legendNFT.getTokenAcceptedTokens(
            _tokenId
        );
        bool isAccepted = false;

        for (uint256 j = 0; j < acceptedTokens.length; j++) {
            if (acceptedTokens[j] == _chosenTokenAddress) {
                isAccepted = true;
                break;
            }
        }
        require(
            isAccepted,
            "LegendFulfillment: Chosen token address is not an accepted token for the collection"
        );

        uint256 totalPrice = calculateTotalPrice(
            _apparelItems,
            _stickerItems,
            _posterItems,
            _tokenId
        );

        uint256 buyerBalance = IERC20(_chosenTokenAddress).balanceOf(
            msg.sender
        );
        require(
            buyerBalance >= totalPrice,
            "LegendFulfillment: Insufficient balance"
        );

        uint256 allowance = IERC20(_chosenTokenAddress).allowance(
            msg.sender,
            address(this)
        );

        require(
            allowance >= totalPrice,
            "LegendFulfillment: Insufficient Approval Allowance"
        );

        orderSupply++;

        transferPayment(
            _tokenId,
            _uri,
            _chosenTokenAddress,
            totalPrice,
            _fulfillerId
        );

        emit OrderCreated(orderSupply, msg.sender, totalPrice);
    }

    function transferPayment(
        uint256 _tokenId,
        string memory _uri,
        address _chosenTokenAddress,
        uint256 _totalPrice,
        uint256 _fulfillerId
    ) internal {
        Order memory newOrder = Order({
            orderId: orderSupply,
            tokenId: _tokenId,
            uri: _uri,
            buyer: msg.sender,
            chosenAddress: _chosenTokenAddress,
            totalPrice: _totalPrice,
            timestamp: block.timestamp,
            status: "ordered",
            isFulfilled: false,
            fulfillerId: _fulfillerId
        });

        orders[orderSupply] = newOrder;
        address creator = legendNFT.getTokenCreator(_tokenId);

        IERC20(_chosenTokenAddress).transferFrom(
            msg.sender,
            creator,
            _totalPrice -
                _totalPrice *
                fulfillers[_fulfillerId].fulfillerPercent
        );

        IERC20(_chosenTokenAddress).transferFrom(
            msg.sender,
            fulfillers[_fulfillerId].fulfillerAddress,
            _totalPrice * fulfillers[_fulfillerId].fulfillerPercent
        );
    }

    // set for oracles
    function setFulfillmentOracle() public onlyAdmin {}

    // set for oracles
    function calculateTotalPrice(
        uint256[] memory _apparelItems,
        uint256[] memory _stickerItems,
        uint256[] memory _posterItems,
        uint256 _collectionId
    ) internal view returns (uint256) {
        uint256 totalPrice = 0;

        if (_apparelItems.length > 0) {
            uint256[] memory apparelPrices = getApparelPrices(_collectionId);

            for (uint256 i = 0; i < _apparelItems.length; i++) {
                totalPrice += apparelPrices[_apparelItems[i]];
            }
        }

        if (_stickerItems.length > 0) {
            uint256[] memory stickerPrices = getStickerPrices(_collectionId);
            for (uint256 i = 0; i < _stickerItems.length; i++) {
                totalPrice += stickerPrices[_stickerItems[i]];
            }
        }

        if (_posterItems.length > 0) {
            uint256[] memory posterPrices = getPosterPrices(_collectionId);
            for (uint256 i = 0; i < _posterItems.length; i++) {
                totalPrice += posterPrices[_posterItems[i]];
            }
        }

        return totalPrice;
    }

    function addFulfillmentToCollection(
        uint256 _collectionId,
        uint256[] memory _apparelPrices,
        uint256[] memory _stickerPrices,
        uint256[] memory _posterPrices
    ) external onlyCreator(_collectionId) {
        FulfillmentPrices memory newFulfillmentPrices = FulfillmentPrices({
            apparelPrices: _apparelPrices,
            stickerPrices: _stickerPrices,
            posterPrices: _posterPrices
        });

        fulfillToCollection[_collectionId] = newFulfillmentPrices;

        legendCollection.setCollectionFulfillment(_collectionId);
    }

    function updateLegendNFT(
        address _newLegendNFTAddress
    ) external onlyAdmin {
        address oldAddress = address(legendNFT);
        legendNFT = LegendNFT(_newLegendNFTAddress);
        emit LegendNFTUpdated(
            oldAddress,
            _newLegendNFTAddress,
            msg.sender
        );
    }

    function updateAccessControl(
        address _newAccessControlAddress
    ) external onlyAdmin {
        address oldAddress = address(accessControl);
        accessControl = AccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function updateLegendCollection(
        address _newLegendCollectionAddress
    ) external onlyAdmin {
        address oldAddress = address(legendCollection);
        legendCollection = LegendCollection(
            _newLegendCollectionAddress
        );
        emit LegendCollectionUpdated(
            oldAddress,
            _newLegendCollectionAddress,
            msg.sender
        );
    }

    function updateFulfillerPercent(
        uint256 _fulfillerId,
        uint256 _fulfillerPercent
    ) public {
        fulfillers[_fulfillerId].fulfillerPercent = _fulfillerPercent;
        emit FulfillerPercentUpdated(_fulfillerId, _fulfillerPercent);
    }

    function getFulfillerPercent(
        uint256 _fulfillerId
    ) public view returns (uint256) {
        return fulfillers[_fulfillerId].fulfillerPercent;
    }

    function updateFulfillerAddress(
        uint256 _fulfillerId,
        address _fulfillerAddress
    ) public {
        fulfillers[_fulfillerId].fulfillerAddress = _fulfillerAddress;
        emit FulfillerAddressUpdated(_fulfillerId, _fulfillerAddress);
    }

    function getFulfillerAddress(
        uint256 _fulfillerId
    ) public view returns (address) {
        return fulfillers[_fulfillerId].fulfillerAddress;
    }

    function getOrderTokenId(uint256 _orderId) public view returns (uint256) {
        return orders[_orderId].tokenId;
    }

    function getOrderUri(uint256 _orderId) public view returns (string memory) {
        return orders[_orderId].uri;
    }

    function getOrderBuyer(uint256 _orderId) public view returns (address) {
        return orders[_orderId].buyer;
    }

    function getOrderChosenAddress(
        uint256 _orderId
    ) public view returns (address) {
        return orders[_orderId].chosenAddress;
    }

    function getOrderTotalPrice(
        uint256 _orderId
    ) public view returns (uint256) {
        return orders[_orderId].totalPrice;
    }

    function getOrderTimestamp(uint256 _orderId) public view returns (uint256) {
        return orders[_orderId].timestamp;
    }

    function getOrderStatus(
        uint256 _orderId
    ) public view returns (string memory) {
        return orders[_orderId].status;
    }

    function getOrderIsFulfilled(uint256 _orderId) public view returns (bool) {
        return orders[_orderId].isFulfilled;
    }

    function getOrderFulfillerId(
        uint256 _orderId
    ) public view returns (uint256) {
        return orders[_orderId].fulfillerId;
    }

    function getStickerPrices(
        uint256 _collectionId
    ) public view returns (uint256[] memory) {
        return fulfillToCollection[_collectionId].stickerPrices;
    }

    function getApparelPrices(
        uint256 _collectionId
    ) public view returns (uint256[] memory) {
        return fulfillToCollection[_collectionId].apparelPrices;
    }

    function getPosterPrices(
        uint256 _collectionId
    ) public view returns (uint256[] memory) {
        return fulfillToCollection[_collectionId].posterPrices;
    }

    function setStickerPrices(
        uint256 _collectionId,
        uint256[] memory _newStickerPrices
    ) public onlyCreator(_collectionId) {
        uint256[] memory oldStickerPrices = fulfillToCollection[_collectionId]
            .stickerPrices;
        fulfillToCollection[_collectionId].stickerPrices = _newStickerPrices;
        emit CollectionStickerPricesUpdated(
            _collectionId,
            oldStickerPrices,
            _newStickerPrices,
            msg.sender
        );
    }

    function setApparelPrices(
        uint256 _collectionId,
        uint256[] memory _newApparelPrices
    ) public onlyCreator(_collectionId) {
        uint256[] memory oldApparelPrices = fulfillToCollection[_collectionId]
            .apparelPrices;
        fulfillToCollection[_collectionId].apparelPrices = _newApparelPrices;
        emit CollectionApparelPricesUpdated(
            _collectionId,
            oldApparelPrices,
            _newApparelPrices,
            msg.sender
        );
    }

    function setPosterPrices(
        uint256 _collectionId,
        uint256[] memory _newPosterPrices
    ) public onlyCreator(_collectionId) {
        uint256[] memory oldPosterPrices = fulfillToCollection[_collectionId]
            .posterPrices;
        fulfillToCollection[_collectionId].posterPrices = _newPosterPrices;
        emit CollectionPosterPricesUpdated(
            _collectionId,
            oldPosterPrices,
            _newPosterPrices,
            msg.sender
        );
    }
}
