// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./LegendCollection.sol";
import "./LegendMarketplace.sol";
import "./AccessControl.sol";
import "./LegendNFT.sol";

contract LegendEscrow is ERC721Holder {
    AccessControl public accessControl;
    LegendCollection public legendCollection;
    LegendMarketplace public legendMarketplace;
    LegendNFT public legendNFT;
    string public symbol;
    string public name;

    mapping(uint256 => bool) private _deposited;

    event LegendMarketplaceUpdated(
        address indexed oldLegendMarketplace,
        address indexed newLegendMarketplace,
        address updater
    );
    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
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

    constructor(
        address _legendCollectionContract,
        address _legendMarketplaceContract,
        address _accessControlContract,
        address _legendNFTContract,
        string memory _symbol,
        string memory _name
    ) {
        legendCollection = LegendCollection(_legendCollectionContract);
        legendMarketplace = LegendMarketplace(
            _legendMarketplaceContract
        );
        accessControl = AccessControl(_accessControlContract);
        legendNFT = LegendNFT(_legendNFTContract);
        symbol = _symbol;
        name = _name;
    }

    modifier onlyAdmin() {
        require(
            accessControl.isAdmin(msg.sender),
            "AccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyDepositer() {
        require(
            msg.sender == address(legendCollection) ||
                msg.sender == address(legendNFT),
            "LegendEscrow: Only the Legend Collection or NFT contract can call this function"
        );
        _;
    }

    modifier onlyReleaser(bool _isBurn, uint256 _tokenId) {
        require(
            msg.sender == address(legendMarketplace) ||
                msg.sender == address(legendCollection) ||
                msg.sender == address(legendNFT),
            "LegendEscrow: Only the Legend Marketplace contract can call this function"
        );
        if (_isBurn) {
            require(
                legendNFT.getTokenCreator(_tokenId) == msg.sender ||
                    address(legendCollection) == msg.sender,
                "LegendEscrow: Only the creator of the token can transfer it to the burn address"
            );
        }
        _;
    }

    function deposit(uint256 _tokenId, bool _bool) external onlyDepositer {
        require(
            legendNFT.ownerOf(_tokenId) == address(this),
            "LegendEscrow: Token must be owned by escrow contract or Owner"
        );
        _deposited[_tokenId] = _bool;
    }

    function release(
        uint256 _tokenId,
        bool _isBurn,
        address _to
    ) external onlyReleaser(_isBurn, _tokenId) {
        require(
            _deposited[_tokenId],
            "LegendEscrow: Token must be in escrow"
        );
        _deposited[_tokenId] = false;
        if (_isBurn) {
            legendNFT.burn(_tokenId);
        } else {
            legendNFT.safeTransferFrom(address(this), _to, _tokenId);
        }
    }

    function updateLegendMarketplace(
        address _newLegendMarketplace
    ) external onlyAdmin {
        address oldAddress = address(accessControl);
        legendMarketplace = LegendMarketplace(_newLegendMarketplace);
        emit LegendMarketplaceUpdated(
            oldAddress,
            _newLegendMarketplace,
            msg.sender
        );
    }

    function updateLegendCollection(
        address _newLegendCollection
    ) external onlyAdmin {
        address oldAddress = address(legendCollection);
        legendCollection = LegendCollection(_newLegendCollection);
        emit LegendCollectionUpdated(
            oldAddress,
            _newLegendCollection,
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
}
