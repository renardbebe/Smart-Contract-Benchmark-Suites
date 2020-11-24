 

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

 
contract ShareholderDividend is Ownable{
    using SafeMath for uint256;
    bool public IsWithdrawActive = true;
    
     
    mapping(address => uint256) EtherBook;

    event withdrawLog(address userAddress, uint256 amount);

    function() public payable{}

     
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
    
     
    function CheckBalance(address theAddress) public view returns(uint256 profit)
    {
        return EtherBook[theAddress];
    }
    
     
    function withdraw() public payable
    {
         
        require(IsWithdrawActive == true, "Vault is not ready.");
        require(EtherBook[msg.sender]>0, "Your vault is empty.");

        uint share = EtherBook[msg.sender];
        EtherBook[msg.sender] = 0;
        msg.sender.transfer(share);
        
        emit withdrawLog(msg.sender, share);
    }
    
     
    function UpdateActive(bool _IsWithdrawActive) public onlyOwner
    {
        IsWithdrawActive = _IsWithdrawActive;
    }
}