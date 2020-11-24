 

pragma solidity ^0.5.1;
library SafeMath {
   
  function Smul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }
      uint256 z = a * b;
      assert((a == 0)||(z/a == b));
      return z;
  }
   
  function Sdiv(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
          return 0;
      }
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
    return c;
  }
   
  function Sadd(uint256 a, uint256 b) internal pure returns (uint256 c) {
      uint256 z = a + b;
      require((z >= a) && (z >= b),'Result must be greater than parameters');
      assert((z >= a) && (z >= b));
      return z;
  }
}
contract PoliPrice{
     
    function readETHUSD() public view returns(uint16);
    function readUSDWEI() public view returns(uint256);
}
contract PoliToken{ 
     
   function balanceOf(address who) public view returns (uint256);
   function transfer(address to, uint256 value) public payable returns (bool);
}
contract PoliChange{
     
    using SafeMath for uint256;
    address constant public cpolitokenAddress = 0x3F041a9705fd66E0E795fb1fBCA3896030F0679D;  
    address constant public cpoliPrice = 0xaf4F368061840f34e4CDeC6Ba96D0Ab6B62b632F;  
    address internal seller;
    address internal buyer; 
    bool    internal waitDeposit;
    uint internal percentGain; 
    PoliToken internal pToken;
    PoliPrice internal pPrice;
    constructor() public{
        seller = msg.sender;
        waitDeposit = true; 
        pToken = PoliToken(cpolitokenAddress); 
        pPrice = PoliPrice(cpoliPrice);
        percentGain = 0;  
    }
     
    function getBalanceETH() public view returns(uint){
        return address(this).balance;
    }
    function getBalancePOLI() public view returns(uint){
        return pToken.balanceOf(address(this));
    }
    function getSellerAddress() public view returns(address){
        return address(seller);
    }
    function getBuyerAddress() public view returns(address){
        return address(buyer);
    }
    function getContractAddress() public view returns(address){
        return address(this);
    }
    function getContractWEIValue() public view returns(uint){ 
        return SafeMath.Smul(getWEIGain(), getBalancePOLI()); 
    }
    function getUSDPrice() public view returns(uint){
        return pPrice.readETHUSD();
    }
    function getWEIGain() private view returns(uint){
        uint rWEIprice;
        uint gainprice;
        rWEIprice = SafeMath.Smul(1, pPrice.readUSDWEI());
        gainprice = SafeMath.Sdiv(SafeMath.Smul(rWEIprice,percentGain),100);
        return SafeMath.Sadd(rWEIprice,gainprice);
    }
     
    function buyTokens() public payable chkBuy() returns(bool){
        if (getBalancePOLI() > 0){
           buyer = msg.sender;
           waitDeposit = false;
           bool ret;
           ret = pToken.transfer(buyer, pToken.balanceOf(address(this)));
           return ret; 
        }
        else{
            return false;
        }
    }
    function sellerToWithdraw() public payable isSeller() returns(bool){
        if (address(this).balance > 0){
           msg.sender.transfer(address(this).balance);
           return true;
        } 
        else{
            return false;
        }
    }
     
    modifier isSeller(){
        require(msg.sender == seller, 'Sorry, you must be the seller');
        _;
    }
    modifier isBuyer(){
        require(msg.sender == buyer, 'Sorry, you must be the buyer');
        _;
    } 
    modifier chkBuy(){
        require(waitDeposit == true, 'Sorry, This contract has already been purchased.');
        require(msg.value == getContractWEIValue(), 'You must to deposit the full value of contract. Check response of function getContractWEIValue() first');
        require(msg.sender != address(0),'Address need to be different of zero');
        _;
    }
    
}