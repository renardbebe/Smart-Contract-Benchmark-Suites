 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function balanceOf(address who) public view returns  (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

  
contract Ownable {
    address public owner;

 
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "only for owner");
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

 
contract RewardSharing is Ownable{
    using SafeMath for uint256;
    bool IsWithdrawActive = true;

     
    mapping(address => uint256) EtherBook;
    mapping(address=> mapping(address => uint256)) TokenBook;
    address[] supportToken;

    event withdrawLog(address userAddress, uint256 etherAmount, uint256 tokenAmount);

     
    function GetTokenLen() public view returns(uint256)
    {
        return supportToken.length;
    }
    
     
    function GetSupportToken(uint index) public view returns(address)
    {
        return supportToken[index];
    }
    
     
    function DepositVault() public payable
    {
        require(msg.value > 0, 'must bigger than zero');
    }

     
    function ProfitDividend (address[] addressArray, uint256[] profitArray) public onlyOwner
    {
        for( uint256 i = 0; i < addressArray.length;i++)
        {
            EtherBook[addressArray[i]] = EtherBook[addressArray[i]].add(profitArray[i]);
        }
    }
    
     
    function AdjustEtherBook(address[] addressArray, uint256[] profitArray) public onlyOwner
    {
        for( uint256 i = 0; i < addressArray.length;i++)
        {
            EtherBook[addressArray[i]] = profitArray[i];
        }
    }
    
     
    function ProfitTokenDividend (address ERC20Address, address[] addressArray, uint256[] profitArray) public onlyOwner
    {
        if(TokenBook[ERC20Address][0x0]== 0)
        {
            supportToken.push(ERC20Address);
            TokenBook[ERC20Address][0x0] = 1;
        }
        
        for( uint256 i = 0; i < addressArray.length;i++)
        {
            TokenBook[ERC20Address][addressArray[i]] = TokenBook[ERC20Address][addressArray[i]].add(profitArray[i]);
        }
    }
    
     
    function AdjustTokenBook(address ERC20Address,address[] addressArray, uint256[] profitArray) public onlyOwner
    {
        if(TokenBook[ERC20Address][0x0]== 0)
        {
            supportToken.push(ERC20Address);
            TokenBook[ERC20Address][0x0] = 1;
        }
        
        for( uint256 i = 0; i < addressArray.length;i++)
        {
            TokenBook[ERC20Address][addressArray[i]] = profitArray[i];
        }
    }
    
     
    function CheckBalance(address theAddress) public view returns(uint256 EtherProfit)
    {
        return (EtherBook[theAddress]);
    }
    
     
    function CheckTokenBalance(address ERC20Address, address theAddress) public view returns(uint256 TokenProfit)
    {
        return TokenBook[ERC20Address][theAddress];
    }
    
     
    function withdraw() public payable
    {
         
        require(IsWithdrawActive == true, "NotVault is not ready.");

        uint etherShare = EtherBook[msg.sender];
        EtherBook[msg.sender] = 0;
        msg.sender.transfer(etherShare);

        for( uint256 i = 0;i< supportToken.length;i++)
        {
            uint tokenShare = TokenBook[supportToken[i]][msg.sender];
            TokenBook[supportToken[i]][msg.sender]= 0;
    
            ERC20(supportToken[i]).transfer(msg.sender, tokenShare);
        }
        emit withdrawLog(msg.sender, etherShare, tokenShare);
    }
    
    function getERC20Back(address ERC20Address,uint amount) public onlyOwner{
        ERC20(ERC20Address).transfer(msg.sender, amount);
    }
    
     
    function UpdateActive(bool _IsWithdrawActive) public onlyOwner
    {
        IsWithdrawActive = _IsWithdrawActive;
    }
}