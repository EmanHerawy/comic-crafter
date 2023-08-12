// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
 import {BookPublisher, Config} from '../src/BookPublisher.sol';
 import {CrossChainTokenSender} from '../src/CrossChainTokenSender.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../script/Helper.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

 contract DummyToken is ERC20{
    constructor() ERC20("my test payment token", "MTPT"){
       
    }

    function mint(address to , uint256 amount)  external{
        _mint(to, amount);
        
    }
 }

contract TestBookPublisher is Test , Helper{


    address Bob = address(456);
    address Alice = address(789);
    address player1 = address(987);
    address author= address(123);
    BookPublisher publisher ;
    DummyToken paymentToken;
Config  _config ;
 string   uri_ = "http://";
    function setUp() external {
    // deploy sender 
    // deploy receiver 
    
    // 
   
    paymentToken = new DummyToken();
       _config ;
            _config.author=author;
            _config.paymentToken=address(paymentToken);
            _config.regularNFTCap=1000;
            _config.superNFTCap=10;
            _config.saleTime= block.timestamp + 30 days;
            _config.saleEndTime= block.timestamp + (30 days *5);
            _config.salePrice = 2 wei;
            _config.superNFTPrice= 0.0001 ether;
            (address sourceRouter, address linkToken, , ) = getConfigFromNetwork(
            SupportedNetworks.AVALANCHE_FUJI
        );
        (address desinationRouter,  , , uint64 destinationChainId) = getConfigFromNetwork( SupportedNetworks.ETHEREUM_SEPOLIA);
     
     
    // publisher = new BookPublisher(desinationRouter, sourceRouter,linkToken,uri_,_config);
    } 
    function testDefualtValues()  public{
        assertEq(author, publisher.author()); 
        assertEq(uri_, publisher.uri(1));
        assertEq(_config.superNFTPrice, publisher.superNFTPrice());
        assertEq(_config.superNFTCap, publisher.superNFTCap());
        assertEq(_config.regularNFTCap, publisher.regularNFTCap());
        assertEq(_config.salePrice, publisher.salePrice());
        assertEq(_config.salePrice, publisher.salePrice());
        assertEq(_config.saleTime, publisher.saleTime());
        assertEq(_config.saleEndTime, publisher.saleEndTime());
        assertEq(_config.paymentToken, publisher.paymentToken());
    }

    function testRegularNFTShouldFailBeforeTime() external {
            vm.startPrank(player1);
            // mint token 
            paymentToken.mint(player1 ,0.0002 ether);

            // approve the publisher 
            paymentToken.approve(address(publisher), type(uint256).max);
            // purchase super nft 
               vm.expectRevert();
            publisher.buyRegularNFT(player1);
         
            vm.stopPrank();
      

    }
    function testMintSuperNFT() external {
        uint256 authorBalance = paymentToken.balanceOf(author);
            vm.startPrank(Bob);
            // mint token 
            paymentToken.mint(Bob ,0.0002 ether);

            // approve the publisher 
            paymentToken.approve(address(publisher), type(uint256).max);
            // purchase super nft 
            publisher.buySuperNFT(Bob);
            // check the balance 
           assertEq( publisher.balanceOf(Bob, 0),1);
// author should receive the payment 

            assertLe(authorBalance,paymentToken.balanceOf(author));
            // try to mint another one , should fail
           vm.expectRevert();
           publisher.buySuperNFT(Bob);
            vm.stopPrank();
            // alic can't int super nt after pre sale 

           vm.startPrank(Alice);
            vm.warp(1680616584 + publisher.saleTime() + 1 hours);
             paymentToken.mint(Alice ,0.0002 ether);

            // approve the publisher 
            paymentToken.approve(address(publisher), type(uint256).max);
            // purchase super nft 
                  vm.expectRevert();
            publisher.buySuperNFT(Alice);
            vm.stopPrank();

    }
    function testMintRegularNFT() external {

            vm.startPrank(player1);
                        vm.warp(1016584 + publisher.saleTime() + 1 hours);

            // mint token 
            paymentToken.mint(player1 ,0.000002 ether);

            // approve the publisher 
            paymentToken.approve(address(publisher), type(uint256).max);
            // purchase super nft 
            publisher.buyRegularNFT(player1);
            // check the balance 
           assertEq( publisher.balanceOf(player1, 1),1);
  vm.stopPrank();
            // try to mint another one  after sales end, should fail
                                    vm.warp(1016584 + publisher.saleEndTime() + 1 hours);

         
           vm.startPrank(Alice);
              paymentToken.mint(Alice ,0.0002 ether);

        //     // approve the publisher 
            paymentToken.approve(address(publisher), type(uint256).max);
        //     // purchase super nft 
                  vm.expectRevert();
            publisher.buyRegularNFT(Alice);
            vm.stopPrank();

    }

    error CannotMintTwice();
    error InvalidOrEmptyArguments();
}
 
// contract NFTMinter is Script, Helper {
// //    enum PayFeesIn {
// //         Native,
// //         LINK
// //     }
// //      struct Config {
// //       uint256   superNFTCap ;
// //      uint256   regularNFTCap ;
// //      uint256   saleTime ;
// //      uint256   saleEndTime ;
// //      uint256   salePrice;
// //      uint256   superNFTPrice;
// //     address    paymentToken;
// //     address       author;
// //  }
//     // run sepholia to avalanche fujji
//     function deploySender(
//         SupportedNetworks source
//     ) external returns ( CrossChainTokenSender sender) {

        
     
//         uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(senderPrivateKey);

//         (address sourceRouter, address linkToken, , ) = getConfigFromNetwork(
//             source
//         );
 
 
//         sender = new  CrossChainTokenSender(sourceRouter, linkToken);
 
//      // send some link token to the contract to be used to pay fees
//      IERC20(linkToken).transfer(address(sender),1 ether);

//         console.log(
//             " your contract is deployed at address: ",address(sender)  );
        

//         vm.stopBroadcast();
         
//     }

    

//     function getFees(
        
//          address  _token,
//          uint256 _amount,
//         SupportedNetworks source,
//         SupportedNetworks destination,
//          address receiver
//     ) external returns (uint256 fees) {
 
     
//         uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(senderPrivateKey);

//         (address sourceRouter, address linkToken, , ) = getConfigFromNetwork(
//             source
//         );
//         (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);

 
//         Client.EVMTokenAmount[]  memory tokens = new Client.EVMTokenAmount[](1);
//         tokens[0]=  Client.EVMTokenAmount({
//             token:_token,
//             amount:_amount
//         });

//         Client.EVM2AnyMessage memory _message = Client.EVM2AnyMessage({
//             receiver: abi.encode(address(receiver)),
//               data:"",
//             tokenAmounts: tokens,
//             extraArgs:"",
//             feeToken: linkToken
//         });

//           fees = IRouterClient(sourceRouter).getFee(
//             destinationChainId,
//             _message
//         );
 
     

//         console.log("fees: ", fees);
 
//         vm.stopBroadcast();
//     }
//     function send(
//          address payable sender,
      
//         address receiver,
//           SupportedNetworks destination,
//           SupportedNetworks source,
//         address _token,
//         uint256 _amount,
        
//         uint256 fees
//      ) external {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(deployerPrivateKey);
//            (, address linkToken, , ) = getConfigFromNetwork(
//             source
//         );
//          IERC20(linkToken).transfer(sender,fees);
//         (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);
//         IERC20(_token).transfer(sender, _amount);
//          bytes32 messageId =  CrossChainTokenSender(sender).send(
           
//         destinationChainId,    receiver,   _token,   _amount
             
//         );/**    uint64 destinationChainSelector,
//         address receiver,
//         address _token,
//         uint256 _amount,
//          PayFeesIn payFeesIn */

//         console.log(
//             "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
//         );
//         console.logBytes32(messageId);

//         vm.stopBroadcast();
//     }
  
//     function deployReceiver(
//        SupportedNetworks destination,
//        SupportedNetworks source,
//        string memory uri_
//     ) external returns ( BookPublisher receiver) {

//       /**address r_router,  address s_router ,address _linktoken ,string memory uri_,Config memory _config */
    
//         uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(senderPrivateKey);
         
//      (address sourceRouter, address linkToken, , ) = getConfigFromNetwork(
//             source
//         );
//         (address desinationRouter, , , ) = getConfigFromNetwork(destination);

//    Config memory _config ;
//             _config.author=msg.sender;
//             _config.paymentToken=linkToken;
//             _config.regularNFTCap=1000;
//             _config.superNFTCap=10;
//             _config.saleTime= block.timestamp + 30 days;
//             _config.saleEndTime= block.timestamp + (30 days *5);
//             _config.salePrice = 2 wei;
//             _config.superNFTPrice= 0.0001 ether;
            
     
//     receiver = new BookPublisher(desinationRouter, sourceRouter,linkToken,uri_,_config);

 

//         console.log( " your contract is deployed at address: ",address(receiver)  );
 
//         vm.stopBroadcast();

        
//     }
// }
