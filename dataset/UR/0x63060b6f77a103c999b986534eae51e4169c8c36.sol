 

 
pragma solidity >=0.4.10;

 
contract Token {
    function balanceOf(address addr) returns(uint);
    function transfer(address to, uint amount) returns(bool);
}

 
contract Receiver {
    event StartSale();
    event EndSale();
    event EtherIn(address from, uint amount);

    address public owner;     
    address public newOwner;  
    string public notice;     

    Sale public sale;

    function Receiver() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlySale() {
        require(msg.sender == address(sale));
        _;
    }

    function live() constant returns(bool) {
        return sale.live();
    }

     
    function start() onlySale {
        StartSale();
    }

     
    function end() onlySale {
        EndSale();
    }

    function () payable {
         
        EtherIn(msg.sender, msg.value);
        require(sale.call.value(msg.value)());
    }

     
    function changeOwner(address next) onlyOwner {
        newOwner = next;
    }

     
    function acceptOwnership() {
        require(msg.sender == newOwner);
        owner = msg.sender;
        newOwner = 0;
    }

     
    function setNotice(string note) onlyOwner {
        notice = note;
    }

     
    function setSale(address s) onlyOwner {
        sale = Sale(s);
    }

     
     
     

     
    function withdrawToken(address token) onlyOwner {
        Token t = Token(token);
        require(t.transfer(msg.sender, t.balanceOf(this)));
    }

     
    function refundToken(address token, address sender, uint amount) onlyOwner {
        Token t = Token(token);
        require(t.transfer(sender, amount));
    }
}

contract Sale {
     
     
     
    uint public constant SOFTCAP_TIME = 4 hours;

    address public owner;     
    address public newOwner;  
    string public notice;     
    uint public start;        
    uint public end;          
    uint public cap;          
    uint public softcap;      
    bool public live;         

    Receiver public r0;
    Receiver public r1;
    Receiver public r2;

    function Sale() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function emitBegin() internal {
        r0.start();
        r1.start();
        r2.start();
    }

     
    function emitEnd() internal {
        r0.end();
        r1.end();
        r2.end();
    }

    function () payable {
         
        require(msg.sender == address(r0) || msg.sender == address(r1) || msg.sender == address(r2));
        require(block.timestamp >= start);

         
         
        if (this.balance > softcap && block.timestamp < end && (end - block.timestamp) > SOFTCAP_TIME)
            end = block.timestamp + SOFTCAP_TIME;

         
         
         
         
         
         
        if (block.timestamp > end || this.balance > cap) {
            require(live);
            live = false;
            emitEnd();
        } else if (!live) {
            live = true;
            emitBegin();
        }
    }

    function init(uint _start, uint _end, uint _cap, uint _softcap) onlyOwner {
        start = _start;
        end = _end;
        cap = _cap;
        softcap = _softcap;
    }

    function setReceivers(address a, address b, address c) onlyOwner {
        r0 = Receiver(a);
        r1 = Receiver(b);
        r2 = Receiver(c);
    }

     
    function changeOwner(address next) onlyOwner {
        newOwner = next;
    }

     
    function acceptOwnership() {
        require(msg.sender == newOwner);
        owner = msg.sender;
        newOwner = 0;
    }

     
    function setNotice(string note) onlyOwner {
        notice = note;
    }

     
    function withdraw() onlyOwner {
        msg.sender.transfer(this.balance);
    }

     
    function withdrawSome(uint value) onlyOwner {
        require(value <= this.balance);
        msg.sender.transfer(value);
    }

     
    function withdrawToken(address token) onlyOwner {
        Token t = Token(token);
        require(t.transfer(msg.sender, t.balanceOf(this)));
    }

     
    function refundToken(address token, address sender, uint amount) onlyOwner {
        Token t = Token(token);
        require(t.transfer(sender, amount));
    }
}