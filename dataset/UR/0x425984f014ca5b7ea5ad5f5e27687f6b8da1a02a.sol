 

pragma solidity ^0.5.5;

contract SafeMath { 
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;  
    }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a/b;   
    }
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;  
    }
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;  
    }  
  function safePower(uint a, uint b) internal pure returns (uint256) {
      uint256 c = a**b;
      return c;  
    }
}

contract Token {
  function balanceOf(address _owner) public view returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) public returns (bool success) {}
  function approve(address _spender, uint256 _value) public returns (bool success) {}
  address public issueContract;
}

contract TokenUSDT {
  function approve(address _spender, uint256 _value) public {}
  function transfer(address _to, uint256 _value) public  {}
}

contract TokenIssue {
  function redeemNPA(uint256 _amount,address _token,bool _isReceiveToken) public returns (bool success) {}
  function issue(address _token, uint256 _amount)public returns (bool success) {}
  function redeem(uint256 _amount) public returns (bool success) {}
  address public tokenAddress;
  address public managerToken;    
  uint256 public fee;
  uint8   public decimals;
  mapping (address => bool) public isTransferFrom;
  mapping (address => uint8) public tokenDecimals; 
}

contract ReserveFund is SafeMath{ 
    address payable public owner;   
    address payable public manager; 
    address public  issueContract;
    address public  reciveTokenTo;
     
    constructor () public {  
        owner = msg.sender;
    }  

     
    function () external payable 
    {        
    }    
    
    function changeOwner(address payable _add)public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0x0)) ;
        owner = _add ;
        return true;
    }

    function changeManager(address payable _add)public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0x0)) ;
        manager = _add ;
        return true;
    }

    function changeIssueContract(address payable _add)public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0x0)) ;
        issueContract = _add ;
        return true;
    }

    function changeReciveTokenTo(address payable _add)public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0x0)) ;
        reciveTokenTo = _add ;
        return true;
    }

    function doRedeemNPA(uint256 _amount,address _token,bool _isReceiveToken)public returns (bool success) {		
        require (msg.sender == manager) ;
        require (reciveTokenTo != address(0x0)) ;
        TokenIssue(issueContract).redeemNPA(_amount,_token,_isReceiveToken);
        if(_isReceiveToken == true){
            bool isTransferFrom = TokenIssue(issueContract).isTransferFrom(_token);
            uint _value = safeDiv(safeMul(_amount , safePower(10,TokenIssue(issueContract).tokenDecimals(_token))) , safePower(10,TokenIssue(issueContract).decimals())) ;
              if(isTransferFrom == true){
                   Token(_token).transfer(reciveTokenTo,_value); 
              }else{
                   TokenUSDT(_token).transfer(reciveTokenTo,_value); 
              }             
        }
        return true;
    }

    function doIssue(address _token, uint256 _amount)public returns (bool success) {
        require (msg.sender == manager) ;
        TokenIssue(issueContract).issue(_token,_amount);
        return true;
    }

    function approveToken(address _token, uint256 _amount)public returns (bool success) {
        require (msg.sender == manager) ;
        bool isTransferFrom = TokenIssue(issueContract).isTransferFrom(_token);
        if(isTransferFrom == true){
              Token(_token).approve(issueContract,_amount);
        }else{
            TokenUSDT(_token).approve(issueContract,_amount);
        }      
        return true;
    }
    
    function doRedeem(uint256 _amount)public returns (bool success) {
        require (msg.sender == manager) ;
        TokenIssue(issueContract).redeem(_amount);
        return true;
    }
}