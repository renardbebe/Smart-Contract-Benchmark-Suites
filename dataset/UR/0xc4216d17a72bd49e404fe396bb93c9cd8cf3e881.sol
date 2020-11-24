 

contract AmIOnTheFork {
    function forked() constant returns(bool);
}

contract Owned{

     
    address Owner;

     
    modifier OnlyOwner{
        if(msg.sender != Owner){
            throw;
        }
        _
    }

     
    function Owned(){
        Owner = msg.sender;
    }

}

 
 
contract EtherTransfer is Owned{

     
     
     
    uint constant Fee = 1;
    uint constant Decs = 1000;

    bool public IsEthereum = false; 

     
    event ETHTransfer(address indexed From,address indexed To, uint Value);
    event ETCReturn(address indexed Return, uint Value);

    event ETCTransfer(address indexed From,address indexed To, uint Value);
    event ETHReturn(address indexed Return, uint Value);
    
     
    AmIOnTheFork IsHeOnTheFork = AmIOnTheFork(0x2bd2326c993dfaef84f696526064ff22eba5b362);

     
    function EtherTransfer(){
        IsEthereum = IsHeOnTheFork.forked();
    }

     
    function SendETH(address ETHAddress) returns(bool){
        uint Value = msg.value - (msg.value*Fee/Decs);
         
        if(IsEthereum && ETHAddress.send(Value)){
            ETHTransfer(msg.sender, ETHAddress, Value);
            return true;
        }else if(!IsEthereum && msg.sender.send(msg.value)){
            ETCReturn(msg.sender, msg.value);
            return true;
        }
         
        throw;
    }

     
    function SendETC(address ETCAddress) returns(bool){
        uint Value = msg.value - (msg.value*Fee/Decs);
         
        if(!IsEthereum && ETCAddress.send(Value)){
            ETCTransfer(msg.sender, ETCAddress, Value);
            return true;
        } else if(IsEthereum && msg.sender.send(msg.value)){
            ETHReturn(msg.sender, msg.value);
            return true;
        }
         
        throw;
    }

     
    function (){
        throw;
    }

     
    function WithDraw() OnlyOwner returns(bool){
        if(this.balance > 0 && Owner.send(this.balance)){
            return true;
        }
        throw;
    }

}