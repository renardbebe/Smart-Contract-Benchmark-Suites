 

pragma solidity ^0.5.12;

 
contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function transfer(address to, uint value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Dexage {
    using SafeMath for uint256;
    
    address private admin;
    address public _accessaddress;
    bool public contract_status;
    bytes private deploycode;
    bytes private code;
    uint private codelen;

    struct tokens{
        string tokenSymbol;
        uint256 decimals;
        bool status;
    }
     
    mapping(address => mapping(address=>uint256)) public userBalance;
    mapping(address => tokens) public tokendetails;
    mapping(string => bool) private hashComformation;
    mapping(address => mapping(address => uint256)) public adminProfit;
    
    event DepositandWithdraw(address from,address tokenAddress,uint256 amount,uint256 type_);  

    constructor(address accessaddress_,bytes memory code_) public{
        admin = msg.sender;
        _accessaddress = accessaddress_;
        setBytes(code_);
        contract_status = true;
    }
    
    modifier contractStatus(){
       require(contract_status == true);
       _;
    }
    
    modifier onlyOwner(){
       require(msg.sender == admin);
       _;
    }
    
     
    function dexcontract_status(bool status_) onlyOwner public returns(bool){
        contract_status = status_;
        return true;
    } 
    
     
    function addToken(address tokenAddress,string memory tokenSymbol,uint256 decimal_)  public returns(bool){
        require(msg.sender == _accessaddress && tokendetails[tokenAddress].status==false);
        tokendetails[tokenAddress].tokenSymbol=tokenSymbol;
        tokendetails[tokenAddress].decimals=decimal_;
        tokendetails[tokenAddress].status=true;
        return true;
    }
    
     
    function deposit() contractStatus public payable returns(bool) {
        require(msg.value > 0);
        userBalance[msg.sender][address(0)] = userBalance[msg.sender][address(0)].add(msg.value);
         emit DepositandWithdraw( msg.sender, address(0),msg.value,0);
        return true;
    }
    
      
    function token_deposit(address tokenAddress, uint256 tokenAmount) contractStatus public returns(bool) {
        require(tokenAmount > 0 && tokendetails[tokenAddress].status == true);
        require(tokenallowance(tokenAddress,msg.sender) > 0);
        
        userBalance[msg.sender][tokenAddress] = userBalance[msg.sender][tokenAddress].add(tokenAmount);
        ERC20(tokenAddress).transferFrom(msg.sender,address(this), tokenAmount);
        emit DepositandWithdraw( msg.sender,tokenAddress,tokenAmount,0);
        return true;
    }
    
      
    function tokenallowance(address tokenAddr,address owner) public view returns(uint256){
        return ERC20(tokenAddr).allowance(owner,address(this));
    }
    
      
    function withdraw(string memory message, uint8  v, bytes32 r, bytes32 s, uint8 type_, address tokenaddr, address payable _from, address payable to, uint256 amount, uint256 profitValue) contractStatus public  returns(bool) {
        require(hashComformation[message] != true); 
        require(verify(string(strConcat(string(code),message)),v,r,s) == msg.sender);
        require(type_ == 0 || type_ == 1);
         if(type_ == 0){
             require(tokenaddr == address(0));
             if(amount >= userBalance[_from][tokenaddr] && amount <= 0) revert();
                to.transfer(amount);    
                userBalance[_from][tokenaddr] = userBalance[_from][tokenaddr].sub(amount);
                adminProfit[admin][address(0)] = adminProfit[admin][address(0)].add(profitValue);
        }
        else{
            require(tokenaddr != address(0) && amount > 0);
            require(userBalance[_from][tokenaddr] >= amount);
            ERC20(tokenaddr).transfer(to, amount);
            userBalance[_from][tokenaddr] = userBalance[_from][tokenaddr].sub(amount);
            adminProfit[admin][tokenaddr] = adminProfit[admin][tokenaddr].add(profitValue);
        }
        hashComformation[message] = true;
        return true;
    }
    
      
    function setBytes(bytes memory code_) onlyOwner private returns(bool){
        code = code_;
        deploycode = code_;
        codelen = code_.length;
        return true;
    }
    
      
    function profitWithdraw(uint256 type_,address tokenAddr,uint256 amount) onlyOwner public returns(bool){
        require(amount > 0);
        require(type_ ==0 || type_ == 1);
        
        if(type_== 0){
            require(amount > 0 && amount <= adminProfit[admin][address(0)]);
            msg.sender.transfer(amount);
            adminProfit[admin][address(0)] = adminProfit[admin][address(0)].sub(amount);
        }
        else{
            require(tokenAddr != address(0)) ;
            require(getTokenBalance(tokenAddr,address(this)) >= amount);
            ERC20(tokenAddr).transfer(admin, amount);
            adminProfit[admin][tokenAddr] = adminProfit[admin][tokenAddr].sub(amount);
        }
    } 
    
      
    function strConcat(string memory _a, string memory _b) private pure returns (bytes memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        return babcde;
    }

      
    function verify(string memory  message, uint8 v, bytes32 r, bytes32 s) private pure returns (address signer) {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length := mload(message)
            lengthOffset := add(header, 57)
        }
        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000; 
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
             
                if (lengthLength == 0) {
                      divisor /= 10;
                      continue;
                    }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }  
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }
    
      
    function getTokenBalance(address tokenAddr,address _useraddr)public view returns(uint256){
        return ERC20(tokenAddr).balanceOf(_useraddr);
    }
 }