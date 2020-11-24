 

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

     
     
     
    uint constant Fee = 5;
    uint constant Decs = 10000;

     
    event ETHTransfer(address indexed From,address indexed To, uint Value);
    event ETCTransfer(address indexed From,address indexed To, uint Value);
    
     
    AmIOnTheFork IsHeOnTheFork = AmIOnTheFork(0x2bd2326c993dfaef84f696526064ff22eba5b362);

     
    function SendETH(address ETHAddress) returns(bool){
        uint Value = msg.value - (msg.value*Fee/Decs);
         
        if(IsHeOnTheFork.forked() && ETHAddress.send(Value)){
            ETHTransfer(msg.sender, ETHAddress, Value);
            return true;
        }
         
        throw;
    }

     
    function SendETC(address ETCAddress) returns(bool){
        uint Value = msg.value - (msg.value*Fee/Decs);
         
        if(!IsHeOnTheFork.forked() && ETCAddress.send(Value)){
            ETCTransfer(msg.sender, ETCAddress, Value);
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