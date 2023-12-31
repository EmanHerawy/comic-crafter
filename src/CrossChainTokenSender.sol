// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {Withdraw} from "./Withdraw.sol";

/**
 * This contract is based on chainlink BasicTokenSender implementation
 */
contract CrossChainTokenSender is Withdraw {
  

    address immutable i_router;
    address immutable i_link;
    uint16 immutable i_maxTokensLength;

    event MessageSent(bytes32 messageId);

    constructor(address router, address link) {
        i_router = router;
        i_link = link;
        i_maxTokensLength = 5;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);
    }

    receive() external payable {}

    function getSupportedTokens(
        uint64 chainSelector
    ) external view returns (address[] memory tokens) {
        tokens = IRouterClient(i_router).getSupportedTokens(chainSelector);
    }

    function send(
        uint64 destinationChainSelector,
        address receiver,
        address _token,
        uint256 _amount 
    ) external returns ( bytes32    messageId){
       IERC20(_token).transferFrom(
                msg.sender,
                address(this),
                 _amount
            );
            IERC20( _token).approve(
                i_router,
                 _amount
            );
        Client.EVMTokenAmount [] memory tokensToSendDetails = new Client.EVMTokenAmount[](1);
        tokensToSendDetails[0]= Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokensToSendDetails,
            extraArgs: "",
            feeToken:   i_link
        });

       

            messageId = IRouterClient(i_router).ccipSend(
                destinationChainSelector,
                message
            );

        emit MessageSent(messageId);
    }
}
