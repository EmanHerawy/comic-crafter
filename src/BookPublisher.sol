// create nftlaunchpad contract 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

 import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CCIPReceiver} from "./CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
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
/// @title ComicLaunchPad
/// @notice ComicLaunchPad is a contract for minting comic books as NFTs

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
  

 constructor(address router,  string memory uri_,Config memory _config) CCIPReceiver(router) ERC1155(uri_){
    if(
        _config .superNFTPrice ==0 ||        _config .salePrice ==0 ||
        _config.superNFTCap ==0 ||     _config.regularNFTCap ==0 ||_config. paymentToken == address(0) ||
     _config.saleTime <= block.timestamp || _config.saleTime + block.timestamp > _config.saleEndTime){
        revert();
    }
    
    superNFTCap=_config.superNFTCap;
    regularNFTCap=_config.regularNFTCap;    
    saleTime=_config.saleTime;
    saleEndTime =_config.saleEndTime;
    salePrice =_config .salePrice;
    superNFTPrice =_config .superNFTPrice;
    paymentToken=_config .paymentToken;
    author=_config .author;
  } 


function buySuperNFT( address to) external  {
    // should be before sale time 
    if(block.timestamp>=saleTime){
        revert();
    }
    if (balanceOf(to,uint256(Category.Super))!=0){
        revert();
    }
    if (totalSupply(uint256(Category.Super)) == superNFTCap){
        revert();
    }
    // get the money to purchase the nft
    IERC20(paymentToken).transferFrom(to,author,superNFTPrice);
    // only one per user could be mintes at a time
    _mint( to, uint256(Category.Super),  1, "");
    _mint( to, uint256(Category.StoryCard),  1, "");
   
}
function buyRegularNFT( address to) external  {
    // should be before sale time 
    if(block.timestamp<saleTime || block.timestamp > saleEndTime){
        revert();
    } 
    if (balanceOf(to,uint256(Category.Regular))!=0){
        revert();
    }
         if (totalSupply(uint256(Category.Regular)) == regularNFTCap){
        revert();
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
        revert();
    }
    // get the money to purchase the nft
    IERC20(paymentToken).transferFrom(address(this),author,superNFTPrice);
    // only one per user could be mintes at a time
    _mint( to, uint256(Category.Super),  1, "");
    _mint( to, uint256(Category.StoryCard),  1, "");

}
function _buyRegularNFTCrossChain( address to) internal  {
    // should be before sale time 
    if(block.timestamp<saleTime || block.timestamp > saleEndTime){
        revert();
    } 
    if (balanceOf(to,uint256(Category.Regular))!=0){
        revert();
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
        if(saleEndTime > block.timestamp){
            revert();
        }
        if(balanceOf(msg.sender, uint256(Category.Super))==0){
            revert();
        }
        if(hasWithdrawn[msg.sender]){
            revert();
        }

        if(_amountPerInvestors==0){
            uint256 total = (totalSupply(uint256(Category.Regular)) * salePrice)/2;
            uint256 totalAdoptors = totalSupply(uint256(Category.Super))-1;
            _amountPerInvestors = total/totalAdoptors;

        }
          hasWithdrawn[msg.sender]=true;
        IERC20(paymentToken).transfer(msg.sender, _amountPerInvestors);
      
     
        
    }
    function authorWthdraw() external {
        if(msg.sender!= author){
            revert();
        }
        if(saleEndTime > block.timestamp){
            revert();
        }
        if(balanceOf(msg.sender, uint256(Category.Super))==0){
            revert();
        }
        if(authorHasWithdrawn){
            revert();
        }
          uint256 total = (totalSupply(uint256(Category.Regular)) * salePrice)/2;
          authorHasWithdrawn=true;
        IERC20(paymentToken).transfer(msg.sender, total);
      
     
        
    }
}


