// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.6;

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

interface LegendKeeper {
    function getDeployerAddress() external view returns (address);
}

contract UpkeepIDConsumer {
    LinkTokenInterface public immutable i_link;
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    mapping(address => mapping(uint256 => uint256)) private _upkeepId;

    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry
    ) {
        i_link = _link;
        registrar = _registrar;
        i_registry = _registry;
    }

    function registerAndPredictID(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source
    ) public {
        require(
            LegendKeeper(upkeepContract).getDeployerAddress() == msg.sender,
            "UpkeepIDConsumerExamplev1: Only a grant deployer can register."
        );
        (State memory state, , ) = i_registry.getState();
        uint256 oldNonce = state.nonce;
        bytes memory payload = abi.encode(
            name,
            encryptedEmail,
            upkeepContract,
            gasLimit,
            adminAddress,
            checkData,
            amount,
            source,
            address(this)
        );

        i_link.transferAndCall(
            registrar,
            amount,
            bytes.concat(registerSig, payload)
        );
        (state, , ) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );
            _upkeepId[msg.sender][block.timestamp] = upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }
}
