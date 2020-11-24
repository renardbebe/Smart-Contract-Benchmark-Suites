 

pragma solidity ^0.4.13;

interface EtherShare {
    function NewShare(string nickname, bool AllowUpdated, string content);
}

 
contract EtherShareDonation {

    EtherShare ES = EtherShare(0xc86bdf9661c62646194ef29b1b8f5fe226e8c97e);
    
    struct oneDonation {
        address donator;
        string nickname;
        uint amount;
    }
    oneDonation[] public donations;

    function Donate(string nickname) payable public {
        donations.push(oneDonation(msg.sender, nickname, msg.value));	 
    }

    function FreeShare(string nickname, string content) public {
        uint startGasLeft = gasleft();
        ES.NewShare(nickname, false, content); 
        uint endGasLeft = gasleft();
        msg.sender.send( tx.gasprice*(startGasLeft-endGasLeft+35000) );	 
    }

     
}