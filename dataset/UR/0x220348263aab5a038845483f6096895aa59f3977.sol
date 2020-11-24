 

pragma solidity ^0.4.11;

contract token { function preallocate(address receiver, uint fullTokens, uint weiPrice) public;
                function transferOwnership(address _newOwner) public;
                function acceptOwnership() public;
                }
contract Airdrop {
    token public tokenReward;
    
    function Airdrop(token _addressOfTokenUsedAsTransfer) public{
         tokenReward = token(_addressOfTokenUsedAsTransfer);
    }

    

    function TransferToken (address[] _to, uint _value, uint _weiPrice) public
    {   for (uint i=0; i< _to.length; i++)
        {
        tokenReward.preallocate(_to[i], _value, _weiPrice);
        }
    }

     


    function TransferOwner (address _owner) public {
        tokenReward.transferOwnership(_owner);
    }

     

    function acceptOwner () public {
        tokenReward.acceptOwnership();
    }

     

    function removeContract() public
        {
            selfdestruct(msg.sender);
            
        }   
}