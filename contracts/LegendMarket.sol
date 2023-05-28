// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./LegendCollection.sol";
import "./LegendEscrow.sol";
import "./LegendNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LegendMarket {
    LegendCollection public legendCollection;
    LegendEscrow public legendEscrow;
    LegendNFT public legendNFT;
    AccessControl public accessControl;
    string public symbol;
    string public name;

    mapping(uint256 => uint256) private tokensSold;
    mapping(uint256 => uint256[]) private tokenIdsSold;

    modifier onlyAdmin() {
        require(
            accessControl.isAdmin(msg.sender),
            "AccessControl: Only admin can perform this action"
        );
        _;
    }

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
    event LegendNFTUpdated(
        address indexed oldLegendNFT,
        address indexed newLegendNFT,
        address updater
    );
    event LegendEscrowUpdated(
        address indexed oldLegendEscrow,
        address indexed newLegendEscrow,
        address updater
    );
    event TokensBought(
        uint256[] tokenIds,
        uint256 totalPrice,
        address buyer,
        address chosenAddress
    );

    constructor(
        address _collectionContract,
        address _accessControlContract,
        address _NFTContract,
        string memory _symbol,
        string memory _name
    ) {
        legendCollection = LegendCollection(_collectionContract);
        accessControl = AccessControl(_accessControlContract);
        legendNFT = LegendNFT(_NFTContract);
        symbol = _symbol;
        name = _name;
    }

    function buyTokens(
        uint256[] memory _tokenIds,
        address _chosenTokenAddress
    ) external {
        uint256 totalPrice = 0;
        uint256[] memory prices = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                legendNFT.ownerOf(_tokenIds[i]) == address(legendEscrow),
                "LegendMarket: Token must be owned by Escrow"
            );
            bool isAccepted = false;
            address[] memory acceptedTokens = legendNFT
                .getTokenAcceptedTokens(_tokenIds[i]);
            for (uint256 j = 0; j < acceptedTokens.length; j++) {
                if (acceptedTokens[j] == _chosenTokenAddress) {
                    isAccepted = true;
                    break;
                }
            }
            require(
                isAccepted,
                "LegendMarket: Chosen token address is not an accepted token for the collection"
            );
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address[] memory acceptedTokens = legendNFT
                .getTokenAcceptedTokens(_tokenIds[i]);
            for (uint256 j = 0; j < acceptedTokens.length; j++) {
                if (acceptedTokens[j] == _chosenTokenAddress) {
                    prices[i] = legendNFT.getBasePrices(_tokenIds[i])[j];
                    totalPrice += prices[i];
                    break;
                }
            }
        }

        uint256 allowance = IERC20(_chosenTokenAddress).allowance(
            msg.sender,
            address(this)
        );

        require(
            allowance >= totalPrice,
            "LegendMarket: Insufficient Approval Allowance"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC20(_chosenTokenAddress).transferFrom(
                msg.sender,
                legendNFT.getTokenCreator(_tokenIds[i]),
                prices[i]
            );
            legendEscrow.release(_tokenIds[i], false, msg.sender);
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokensSold[legendNFT.getTokenCollection(_tokenIds[i])] += 1;
            tokenIdsSold[legendNFT.getTokenCollection(_tokenIds[i])].push(
                _tokenIds[i]
            );
        }

        emit TokensBought(
            _tokenIds,
            totalPrice,
            msg.sender,
            _chosenTokenAddress
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

    function setLegendEscrow(
        address _newLegendEscrowAddress
    ) external onlyAdmin {
        address oldAddress = address(legendEscrow);
        legendEscrow = LegendEscrow(_newLegendEscrowAddress);
        emit LegendEscrowUpdated(
            oldAddress,
            _newLegendEscrowAddress,
            msg.sender
        );
    }

    function getCollectionSoldCount(
        uint256 _collectionId
    ) public view returns (uint256) {
        return tokensSold[_collectionId];
    }

    function getTokensSoldCollection(
        uint256 _collectionId
    ) public view returns (uint256[] memory) {
        return tokenIdsSold[_collectionId];
    }
}
