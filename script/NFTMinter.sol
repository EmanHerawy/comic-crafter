// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
 import {CrossChainTokenSender} from "../src/CrossChainTokenSender.sol";
import { BookPublisher , Config} from "../src/BookPublisher.sol";
contract NFTMinter is Script, Helper {
//    enum PayFeesIn {
//         Native,
//         LINK
//     }
//      struct Config {
//       uint256   superNFTCap ;
//      uint256   regularNFTCap ;
//      uint256   saleTime ;
//      uint256   saleEndTime ;
//      uint256   salePrice;
//      uint256   superNFTPrice;
//     address    paymentToken;
//     address       author;
//  }
    // run sepholia to avalanche fujji
    function deploySender(
        SupportedNetworks source
    ) external returns ( CrossChainTokenSender sender) {

        
     
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);

        (address sourceRouter, address linkToken, , ) = getConfigFromNetwork(
            source
        );
 
 
        sender = new  CrossChainTokenSender(sourceRouter, linkToken);
 
     // send some link token to the contract to be used to pay fees
     IERC20(linkToken).transfer(address(sender),1 ether);

        console.log(
            " your contract is deployed at address: ",address(sender)  );
        

        vm.stopBroadcast();
         
    }

    

    function getFees(
        
         address  _token,
         uint256 _amount,
        SupportedNetworks source,
        SupportedNetworks destination,
         address receiver
    ) external returns (uint256 fees) {
 
     
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);

        (address sourceRouter, address linkToken, , ) = getConfigFromNetwork(
            source
        );
        (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);

 
        Client.EVMTokenAmount[]  memory tokens = new Client.EVMTokenAmount[](1);
        tokens[0]=  Client.EVMTokenAmount({
            token:_token,
            amount:_amount
        });

        Client.EVM2AnyMessage memory _message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(receiver)),
              data:"",
            tokenAmounts: tokens,
            extraArgs:"",
            feeToken: linkToken
        });

          fees = IRouterClient(sourceRouter).getFee(
            destinationChainId,
            _message
        );
 
     

        console.log("fees: ", fees);
 
        vm.stopBroadcast();
    }
    function send(
         address payable sender,
      
        address receiver,
          SupportedNetworks destination,
          SupportedNetworks source,
        address _token,
        uint256 _amount,
        
        uint256 fees
     ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
           (, address linkToken, , ) = getConfigFromNetwork(
            source
        );
         IERC20(linkToken).transfer(sender,fees);
        (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);
        IERC20(_token).transfer(sender, _amount);
         bytes32 messageId =  CrossChainTokenSender(sender).send(
           
        destinationChainId,    receiver,   _token,   _amount
             
        );/**    uint64 destinationChainSelector,
        address receiver,
        address _token,
        uint256 _amount,
         PayFeesIn payFeesIn */

        console.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        console.logBytes32(messageId);

        vm.stopBroadcast();
    }
  
    function deployReceiver(
       SupportedNetworks destination,
       SupportedNetworks source
     
    ) external returns ( BookPublisher receiver) {

      /**address r_router,  address s_router ,address _linktoken ,string memory uri_,Config memory _config */
      string memory uri_ = "https://game.example/api/item/{id}.json" ;
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);
         
     (address sourceRouter, address linkToken, , ) = getConfigFromNetwork(
            source
        );
        (address desinationRouter, , , ) = getConfigFromNetwork(destination);
        (address paymentToken, ) = getDummyTokensFromNetwork(destination);
uint256 _saleTime= block.timestamp + 30 days;
uint256 _saleEndTime= block.timestamp + (30 days *5); 
uint256 _salePrice  = 2 wei;
//    Config memory _config ;
//             _config.author=msg.sender;
//             _config.paymentToken=paymentToken;
//             _config.regularNFTCap=1000;
//             _config.superNFTCap=10;
//             _config.saleTime= block.timestamp + 30 days;
//             _config.saleEndTime= block.timestamp + (30 days *5);
//             _config.salePrice = 2 wei;
//             _config.superNFTPrice= 0.0001 ether;


//                 Config ({
//                 author:msg.sender,
//            paymentToken:paymentToken,
//            regularNFTCap:1000,
//            superNFTCap:10,
//            saleTime: block.timestamp + 30 days,
//            saleEndTime: block.timestamp + (30 days *5),
//            salePrice : 2 wei,
//            superNFTPrice: 0.0001 ether
//             })
            
        //     Config memory contractConfig = Config ({
        //         author:msg.sender,
        //    paymentToken:paymentToken,
        //    regularNFTCap:1000,
        //    superNFTCap:10,
        //    saleTime: block.timestamp + 30 days,
        //    saleEndTime: block.timestamp + (30 days *5),
        //    salePrice : 2 wei,
        //    superNFTPrice: 0.0001 ether
        //     });
            
        console.log("before deployment",sourceRouter );
/**address r_router,  address s_router ,address _linktoken, address _paymentToken,uint256 _saleTime, uint256 _saleEndTime, uint256 _salePrice */
    receiver = new BookPublisher(desinationRouter, sourceRouter,linkToken,paymentToken,_saleTime,_saleEndTime,_salePrice );

 

        console.log( " your contract is deployed at address: ",address(receiver)  );
 
        vm.stopBroadcast();

        
    }
}
