// create nftlaunchpad contract 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

 import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CCIPReceiver} from "./CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";


 struct Config {
      uint256   superNFTCap ;
     uint256   regularNFTCap ;
     uint256   saleTime ;
     uint256   saleEndTime ;
     uint256   salePrice;
     uint256   superNFTPrice;
    address    paymentToken;
    address       author;
 }

 /**
    * this contract shold handle issuing comic book nft . since the books issued per auther is not unique given that author issue multiple coppied of the book as nfts , we will implement ERC1155 interface. 
    * with each book minted, a story card is minted to be used inside the game .
    * early addapters have more benefits than those come late to the party, they got 50% of the revnue of the sale 
    * contract should keep traack of the early addapters and manage the payment 
    * cross chain minting is enabled by default 

 */
/// @title BookPublisher
/// @notice BookPublisher is a contract for minting comic books as NFTs

contract BookPublisher  is CCIPReceiver, ERC1155 {
    enum Category {Super, Regular , StoryCard}
     uint256 public immutable superNFTCap ;
     uint256 public immutable regularNFTCap ;
     uint256 public immutable saleTime ;
     uint256 public immutable saleEndTime ;
     address  public  immutable paymentToken;
     address  public  immutable author;
     uint256 public salePrice;
     uint256 public superNFTPrice;
 
     uint256 public _amountPerInvestors;
     bool public authorHasWithdrawn;
    // investors / early adopters mapping to keep track of who has withdrawn his/her share  from the contract
    mapping(address => bool) public hasWithdrawn;
    mapping(uint256 => uint256) private _totalSupply;
  IRouterClient public sendRouter;
LinkTokenInterface public linkToken;


constructor(address r_router,  address s_router ,address _linktoken, address _paymentToken,uint256 _saleTime, uint256 _saleEndTime, uint256 _salePrice) CCIPReceiver(r_router) ERC1155("https://game.example/api/item/{id}.json"){
    // if(
    //     _config .superNFTPrice ==0 ||        _config .salePrice ==0 ||
    //     _config.superNFTCap ==0 ||     _config.regularNFTCap ==0 ||_config. paymentToken == address(0) ||
    //  _config.saleTime <= block.timestamp || _config.saleTime + block.timestamp > _config.saleEndTime){
    //     revert InvalidOrEmptyArguments();
    // }
    
    superNFTCap=10;
    regularNFTCap=100;    
    saleTime=_saleTime;
    saleEndTime =_saleEndTime;
    salePrice =_salePrice;
    superNFTPrice =salePrice *10;
    paymentToken=_paymentToken;
    author=msg.sender;
    sendRouter = IRouterClient(s_router);
     linkToken = LinkTokenInterface(_linktoken);
        // approve router to spend any amount of link as fee
       linkToken.approve(s_router, type(uint256).max);
  } 
//  constructor(address r_router,  address s_router ,address _linktoken ,string memory uri_,Config memory _config ) CCIPReceiver(r_router) ERC1155(uri_){
//     if(
//         _config .superNFTPrice ==0 ||        _config .salePrice ==0 ||
//         _config.superNFTCap ==0 ||     _config.regularNFTCap ==0 ||_config. paymentToken == address(0) ||
//      _config.saleTime <= block.timestamp || _config.saleTime + block.timestamp > _config.saleEndTime){
//         revert InvalidOrEmptyArguments();
//     }
    
//     superNFTCap=_config.superNFTCap;
//     regularNFTCap=_config.regularNFTCap;    
//     saleTime=_config.saleTime;
//     saleEndTime =_config.saleEndTime;
//     salePrice =_config .salePrice;
//     superNFTPrice =_config .superNFTPrice;
//     paymentToken=_config .paymentToken;
//     author=_config .author;
//     sendRouter = IRouterClient(s_router);
//      linkToken = LinkTokenInterface(_linktoken);
//         // approve router to spend any amount of link as fee
//        //linkToken.approve(s_router, type(uint256).max);
//   } 


function buySuperNFT( address to) external  {
    // should be before sale time 
    if(block.timestamp>=saleTime){
        revert SuperNFTSaleEnded();
    }
    if (balanceOf(to,uint256(Category.Super))!=0){
        revert CannotMintTwice();
    }
    if (totalSupply(uint256(Category.Super)) == superNFTCap){
        revert MaxCapReached();
    }
    // get the money to purchase the nft
    IERC20(paymentToken).transferFrom(to,author,superNFTPrice);
    // only one per user could be mintes at a time
    _mint( to, uint256(Category.Super),  1, "");
    _mint( to, uint256(Category.StoryCard),  1, "");
   
}
function buyRegularNFT( address to) external  {
    // should be before sale time 
      if(block.timestamp<saleTime){
        revert SaledIsNotStarted( saleEndTime,block.timestamp );
    } 
    if( block.timestamp > saleEndTime){
        revert SaledEnded(saleEndTime,block.timestamp );
    } 
    if (balanceOf(to,uint256(Category.Regular))!=0){
        revert CannotMintTwice();
    }
         if (totalSupply(uint256(Category.Regular)) == regularNFTCap){
        revert MaxCapReached();
    }
    // contract should hold the money to eb distributed among auther and early adopter 
    IERC20(paymentToken).transferFrom(to,address(this),salePrice);
    // only one per user could be minted at a time
    _mint( to, uint256(Category.Regular),  1, "");
        _mint( to, uint256(Category.StoryCard),  1, "");


}
function _buySuperNFTCrossChain( address to) internal  {
    // should be before sale time 
    
    if (balanceOf(to,uint256(Category.Super))!=0){
        revert CannotMintTwice();
    }
    // get the money to purchase the nft
    IERC20(paymentToken).transferFrom(address(this),author,superNFTPrice);
    // only one per user could be mintes at a time
    _mint( to, uint256(Category.Super),  1, "");
    _mint( to, uint256(Category.StoryCard),  1, "");

}
function _buyRegularNFTCrossChain( address to) internal  {
    // should be before sale time 
    if(block.timestamp<saleTime){
        revert SaledIsNotStarted( saleEndTime,block.timestamp );
    } 
    if( block.timestamp > saleEndTime){
        revert SaledEnded(saleEndTime,block.timestamp );
    } 
    if (balanceOf(to,uint256(Category.Regular))!=0){
        revert CannotMintTwice();
    }
     
    // only one per user could be mintes at a time
    _mint( to, uint256(Category.Regular),  1, "");
    _mint( to, uint256(Category.StoryCard),  1, "");

}



    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {


        
        uint256 tokenAmounts = message.destTokenAmounts[0].amount;
                    address sender = abi.decode(message.sender, (address)); // abi-decoding of the sender address

        if( paymentToken != message.destTokenAmounts[0].token){
            revert();
        } 
         if(block.timestamp<saleTime ){
        // mint super nft 
        if (tokenAmounts < superNFTPrice || totalSupply(uint256(Category.Super)) == superNFTCap){
            revert();
        }

        _buySuperNFTCrossChain(sender);
    } else if(block.timestamp>=saleTime ){
           if (tokenAmounts < salePrice || totalSupply(uint256(Category.Regular)) == regularNFTCap){
            revert();
        }

        _buyRegularNFTCrossChain(sender);
    } 
    }





       /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return this.totalSupply(id) > 0;
    }
  function supportsInterface(bytes4 interfaceId) public view virtual override (CCIPReceiver,ERC1155) returns (bool) {
    return super.supportsInterface(interfaceId);
    }


    /*---------------------------------------------------------------- withdraw --------------------------------*/// @title A title that should describe the contract/interface
    

    function withdraw() external {
        _investorCanWithdraw(msg.sender);
        if(_amountPerInvestors==0){
            uint256 total = (totalSupply(uint256(Category.Regular)) * salePrice)/2;
            uint256 totalAdoptors = totalSupply(uint256(Category.Super))-1;
            _amountPerInvestors = total/totalAdoptors;

        }
          hasWithdrawn[msg.sender]=true;
        IERC20(paymentToken).transfer(msg.sender, _amountPerInvestors);
      
     
        
    }
    function authorWthdraw() external {
                  _authorCanWithdraw( msg.sender);

          uint256 total = (totalSupply(uint256(Category.Regular)) * salePrice)/2;
          authorHasWithdrawn=true;
        IERC20(paymentToken).transfer(msg.sender, total);
      
     
        
    }
    function withdrawCrossChain(uint64 destinationChainSelector) external returns (bytes32 messageId){
       
        if(_amountPerInvestors==0){
            uint256 total = (totalSupply(uint256(Category.Regular)) * salePrice)/2;
            uint256 totalAdoptors = totalSupply(uint256(Category.Super))-1;
            _amountPerInvestors = total/totalAdoptors;

        }
          hasWithdrawn[msg.sender]=true;
        return  _send( msg.sender, paymentToken, _amountPerInvestors,  destinationChainSelector);

      
     
        
    }
    function authorWthdrawCrossChain(uint64 destinationChainSelector) external returns (bytes32 messageId){
            _authorCanWithdraw( msg.sender);
          uint256 total = (totalSupply(uint256(Category.Regular)) * salePrice)/2;
          authorHasWithdrawn=true;
       return  _send( msg.sender, paymentToken, total,  destinationChainSelector);
      
     
        
    }
    function _investorCanWithdraw(address to) internal view {
         if(saleEndTime > block.timestamp){
            revert();
        }
        if(balanceOf(to, uint256(Category.Super))==0){
            revert CannotMintTwice();
        }
        if(hasWithdrawn[to]){
            revert();
        }
       
    }
    function _authorCanWithdraw(address to) internal view {
           if(to != author){
            revert();
        }
        if(saleEndTime > block.timestamp){
            revert();
        }
        
        if(authorHasWithdrawn){
            revert();
        }
    }



        function _send( address _receiver, address _token, uint256 _amount, uint64 destinationChainSelector) internal returns (bytes32 messageId) {
        Client.EVMTokenAmount [] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0]=   Client.EVMTokenAmount({
            token:_token,
            amount:_amount
        });
                Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
        receiver: abi.encode(_receiver),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0, strict: false})
            ),
            feeToken: address(linkToken)
        });
// approve the token 
    IERC20(_token).approve(address(sendRouter), _amount);
     messageId=   sendRouter.ccipSend(destinationChainSelector, message);

    }


    /* -------------------------------- Errors go here --------------------------------*/// @title A title that should describe the contract/interface
    

    error CannotMintTwice();
    error InvalidOrEmptyArguments();
    error SaledEnded( uint256 endtime,uint256 currentTime);
    error SaledIsNotStarted( uint256 start,uint256 currentTime);
    error SuperNFTSaleEnded();
    error MaxCapReached();
}


