 

pragma solidity ^0.4.17;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract InvestorsList is Ownable {
    using SafeMath for uint;

     

    enum WhiteListStatus  {Usual, WhiteList, PreWhiteList}

    struct Investor {
        bytes32 id;
        uint tokensCount;
        address walletForTokens;
        WhiteListStatus whiteListStatus;
        bool isVerified;
    }

     

    mapping (address => bool) manipulators;
    mapping (address => bytes32) public nativeInvestorsIds;
    mapping (bytes32 => Investor) public investorsList;

     

    modifier allowedToManipulate(){
        require(manipulators[msg.sender] || msg.sender == owner);
        _;
    }

    function changeManipulatorAddress(address saleAddress, bool isAllowedToManipulate) external onlyOwner{
        require(saleAddress != 0x0);
        manipulators[saleAddress] = isAllowedToManipulate;
    }

     

    function setInvestorId(address investorAddress, bytes32 id) external onlyOwner{
        require(investorAddress != 0x0 && id != 0);
        nativeInvestorsIds[investorAddress] = id;
    }

    function addInvestor(
        bytes32 id,
        WhiteListStatus status,
        bool isVerified
    ) external onlyOwner {
        require(id != 0);
        require(investorsList[id].id == 0);

        investorsList[id].id = id;
        investorsList[id].tokensCount = 0;
        investorsList[id].whiteListStatus = status;
        investorsList[id].isVerified = isVerified;
    }

    function removeInvestor(bytes32 id) external onlyOwner {
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].id = 0;
    }

    function isAllowedToBuyByAddress(address investor) external view returns(bool){
        require(investor != 0x0);
        bytes32 id = nativeInvestorsIds[investor];
        require(id != 0 && investorsList[id].id != 0);
        return investorsList[id].isVerified;
    }

    function isAllowedToBuyByAddressWithoutVerification(address investor) external view returns(bool){
        require(investor != 0x0);
        bytes32 id = nativeInvestorsIds[investor];
        require(id != 0 && investorsList[id].id != 0);
        return true;
    }

    function isAllowedToBuy(bytes32 id) external view returns(bool){
        require(id != 0 && investorsList[id].id != 0);
        return investorsList[id].isVerified;
    }

    function isPreWhiteListed(bytes32 id) external constant returns(bool){
        require(id != 0 && investorsList[id].id != 0);
        return investorsList[id].whiteListStatus == WhiteListStatus.PreWhiteList;
    }

    function isWhiteListed(bytes32 id) external view returns(bool){
        require(id != 0 && investorsList[id].id != 0);
        return investorsList[id].whiteListStatus == WhiteListStatus.WhiteList;
    }

    function setVerificationStatus(bytes32 id, bool status) external onlyOwner{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].isVerified = status;
    }

    function setWhiteListStatus(bytes32 id, WhiteListStatus status) external onlyOwner{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].whiteListStatus = status;
    }

    function addTokens(bytes32 id, uint tokens) external allowedToManipulate{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].tokensCount = investorsList[id].tokensCount.add(tokens);
    }

    function subTokens(bytes32 id, uint tokens) external allowedToManipulate{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].tokensCount = investorsList[id].tokensCount.sub(tokens);
    }

    function setWalletForTokens(bytes32 id, address wallet) external onlyOwner{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].walletForTokens = wallet;
    }
}