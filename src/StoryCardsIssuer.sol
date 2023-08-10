// create nftlaunchpad contract 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

 import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
 import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";


/// @title StoryCardsIssuer
/// @notice For each copy of newly minted book , users get free story cards

contract StoryCardsIssuer  is ERC721 , OwnerIsCreator{

    /// @dev token id tracker
    uint256 private _tokenIdTracker; 
  
    constructor() ERC721("Comic Story Card", "CSC") {
    }
    

    /// @notice  mint function for each new Comic Story Card
    /// @param _to the address of the receiver
             function mint(address _to) external onlyOwner {
 
              // number is limited , no way to overflow
       unchecked {
        ++ _tokenIdTracker;
       }
        _safeMint(_to, _tokenIdTracker);
    
    }


    
}
