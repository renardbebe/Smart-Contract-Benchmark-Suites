 

contract Splitter {
    
    bool _classic;
    address _owner;
    
    function Splitter() {
        _owner = msg.sender;

         
        if (address(0xbf4ed7b27f1d666546e30d74d50d173d20bca754).balance < 1 ether) {
            _classic = true;
        }
    }

    function isClassic() constant returns (bool) {
        return _classic;
    }
    
     
     
    function split(address classicAddress) {
        if (_classic){
            if (!(classicAddress.send(msg.value))) {
                throw;
            }
        } else {
            if (!(msg.sender.send(msg.value))) {
                throw;
            }
        }
    }

    function claimDonations(uint balance) {
        if (_owner != msg.sender) { return; }
        if (!(_owner.send(balance))) {
            throw;
        }
    }
}