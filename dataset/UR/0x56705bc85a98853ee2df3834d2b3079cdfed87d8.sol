 

contract ConsultingHalf {
     
    address public engineer;
    address public manager;
    uint public createdTime;
    uint public updatedTime;

    function ConsultingHalf(address _engineer, address _manager) {
        engineer = _engineer;
        manager = _manager;
        createdTime = block.timestamp;
        updatedTime = block.timestamp;
    }

     
    function payout() returns (bool _success) {
        if(msg.sender == engineer || msg.sender == manager) {
             engineer.send(this.balance / 2);
             manager.send(this.balance);
             updatedTime = block.timestamp;
             _success = true;
        }else{
            _success = false;
        }
    }
}