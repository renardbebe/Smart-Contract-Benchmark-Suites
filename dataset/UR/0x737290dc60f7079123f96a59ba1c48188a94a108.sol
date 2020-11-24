 

pragma solidity ^0.4.18;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}



  



contract Exchange is Ownable {

    
     
     
    uint256 public transFeeCut =  0;

    enum Errors {
        ORDER_EXPIRED,
        ORDER_FILLED,
        ORDER_CACELD,
        INSUFFICIENT_BALANCE_OR_ALLOWANCE
    }


    struct Order {
        address maker;  
        address taker; 
        address contractAddr;  
        uint256 nftTokenId; 
        uint256 tokenAmount; 
        uint expirationTimestampInSec;  
        bytes32 orderHash;
    }

    event LogFill(
        address indexed maker,
        address taker,
        address contractAddr,
        uint256 nftTokenId,
        uint tokenAmount,
        bytes32 indexed tokens,  
        bytes32 orderHash
    );

    event LogError(uint8 indexed errorId, bytes32 indexed orderHash);

    function getOrderHash(address[3] orderAddresses, uint[4] orderValues)
        public
        constant
        returns (bytes32)
    {
        return keccak256(
            address(this),
            orderAddresses[0],  
            orderAddresses[1],  
            orderAddresses[2],  
            orderValues[0],     
            orderValues[1],     
            orderValues[2],     
            orderValues[3]     
        );
    }



    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
        pure
        returns (bool)
    {
        return signer == ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            v,
            r,
            s
        );
    }



    function fillOrder(
          address[3] orderAddresses,
          uint[4] orderValues,
          uint8 v,
          bytes32 r,
          bytes32 s)
          public
          payable
    {

        Order memory order = Order({
            maker: orderAddresses[0],
            taker: orderAddresses[1],
            contractAddr: orderAddresses[2],
            nftTokenId: orderValues[0],
            tokenAmount : orderValues[1],
            expirationTimestampInSec: orderValues[2],
            orderHash: getOrderHash(orderAddresses, orderValues)
        });


        if (msg.value < order.tokenAmount) {
            LogError(uint8(Errors.INSUFFICIENT_BALANCE_OR_ALLOWANCE), order.orderHash);
            return ;
        }


        require(msg.value >= order.tokenAmount);
        require(order.taker == address(0) || order.taker == msg.sender);


        require(order.tokenAmount > 0 );
        require(isValidSignature(
            order.maker,
            order.orderHash,
            v,
            r,
            s
        ));

        if (block.timestamp >= order.expirationTimestampInSec) {
            LogError(uint8(Errors.ORDER_EXPIRED), order.orderHash);
            return ;
        }


        require( transferViaProxy ( order.contractAddr , order.maker,msg.sender , order.nftTokenId )  );

        uint256 transCut = _computeCut(order.tokenAmount);
        order.maker.transfer(order.tokenAmount - transCut);
        uint256 bidExcess = msg.value - order.tokenAmount;
         
        msg.sender.transfer(bidExcess);
        LogFill(order.maker,msg.sender,order.contractAddr,order.nftTokenId,order.tokenAmount, keccak256(order.contractAddr),order.orderHash );
    }


    function transferViaProxy( address nftAddr, address maker ,address taker , uint256 nftId ) internal returns(bool) 
    {
    
       ERC721(nftAddr).transferFrom( maker, taker , nftId ) ;
       return true;
    }

    function withdrawBalance() external onlyOwner{
        uint256 balance = this.balance;
        owner.transfer(balance);
    }

    function setTransFeeCut(uint256 val) external onlyOwner {
        require(val <= 10000);
        transFeeCut = val;
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * transFeeCut / 10000;
    }

}