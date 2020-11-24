 

pragma solidity ^0.4.16;

 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Big2018Token {
     
     
     
    address public creator;   
     
    uint256 public tokensDaily = 10000;  
    uint256 tokensToday = 0;  
    uint256 public leftToday = 10000;  
    uint startPrice = 100000000000000;  
    uint q = 37;  
    uint countBuy = 0;  
    uint start2018 = 1514764800;  
    uint end2018 = 1546300799;  
    uint day = 1;  
    uint d = 86400;  
    uint dayOld = 1;  
     
    address public game;   
    mapping (address => uint) public box;  
    uint boxRand = 0;  
    uint boxMax = 5;  
    event BoxChange(address who, uint newBox);  
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;  
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);  
    mapping (address => mapping (address => uint256)) public allowance;
     
    struct EscrowTrade {
        uint256 value;  
        uint price;  
        address to;  
        bool open;  
    }
    mapping (address => mapping (uint => EscrowTrade)) public escrowTransferInfo;
    mapping (address => uint) userEscrowCount;
    event Escrow(address from, uint256 value, uint price, bool open, address to);  
    struct EscrowTfr {
        address from;  
        uint tradeNo;  
    }
    EscrowTfr[] public escrowTransferList;  
    uint public escrowCount = 0;

     
     
    function Big2018Token() public {
        creator = msg.sender;  
        game = msg.sender;  
        totalSupply = 3650000 * 10 ** uint256(decimals);   
        balanceOf[this] = totalSupply;      
        name = "BIG2018TOKEN";                 
        symbol = "B18";                        
    }

     
     
    function getPriceWei(uint _day) public returns (uint) {
        require(now >= start2018 && now <= end2018);  
        day = (now - start2018)/d + 1;  
        if (day > dayOld) {   
            uint256 _value = ((day - dayOld - 1)*tokensDaily + leftToday) * 10 ** uint256(decimals);
            _transfer(this, creator, _value);  
            tokensToday = 0;  
            dayOld = day;  
        }
        if (_day != 0) {  
        day = _day;  
        }
         
             
            uint n = day - 1;  
            uint p = 3 + n * 5 / 100;  
            uint s = 0;  
            uint x = 1;  
            uint y = 1;  
             
            for (uint i = 0; i < p; ++i) {  
                s += startPrice * x / y / (q**i);  
                x = x * (n-i);  
                y = y * (i+1);  
            }
            return (s);  
    }

     
     
    function () external payable {
         
        require(now >= start2018 && now <= end2018);  
        uint priceWei = this.getPriceWei(0);  
        uint256 giveTokens = msg.value / priceWei;  
            if (tokensToday + giveTokens > tokensDaily) {  
                giveTokens = tokensDaily - tokensToday;     
                }
        countBuy += 1;  
        tokensToday += giveTokens;  
        box[msg.sender] = this.boxChoice(0);  
        _transfer(this, msg.sender, giveTokens * 10 ** uint256(decimals));  
        uint256 changeDue = msg.value - (giveTokens * priceWei) * 99 / 100;  
        require(changeDue < msg.value);  
        msg.sender.transfer(changeDue);  
        
    }

     
     
    function getValueAndBox(address _address) view external returns(uint, uint) {
        return (balanceOf[_address], box[_address]);
    }

     
     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);  
        require(balanceOf[_from] >= _value);  
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        uint previousbalanceOf = balanceOf[_from] + balanceOf[_to];  
        balanceOf[_from] -= _value;  
        balanceOf[_to] += _value;  
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousbalanceOf);  
    }

     
     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);  
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
     
    function boxChoice(uint _newBox) public returns (uint) { 
         
        boxRand += 1;  
        if (boxRand > boxMax) {  
                    boxRand = 1;  
            }
        if (_newBox == 0) {
            box[msg.sender] = boxRand;  
        } else {
        box[msg.sender] = _newBox;  
        }
        BoxChange(msg.sender, _newBox);  
            return (box[msg.sender]);  
    }

     
     
     
    function fundsOut() payable public { 
        require(msg.sender == creator);  
        creator.transfer(this.balance);  
    }

     
     
    function update(uint _option, uint _newNo, address _newAddress) public returns (string, uint) {
        require(msg.sender == creator || msg.sender == game);  
         
        if (_option == 1) {
            require(_newNo > 0);
            boxMax = _newNo;
            return ("boxMax Updated", boxMax);
        }
         
        if (_option == 2) {
            game = _newAddress;
            return ("Game Smart Contract Updated", 1);
        }
    }

     
     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }

     
     
    function setEscrowTransfer(address _to, uint _value, uint _price, bool _open) external returns (bool success) {
             
             
             
             
             
        _transfer(msg.sender, this, _value);  
        userEscrowCount[msg.sender] += 1;
        var escrowTrade = escrowTransferInfo[msg.sender][userEscrowCount[msg.sender]];  
        escrowTrade.value += _value; 
        escrowTrade.price = _price;  
        escrowTrade.to = _to;  
        escrowTrade.open = _open;  
        escrowCount += 1;
        escrowTransferList.push(EscrowTfr(msg.sender, userEscrowCount[msg.sender]));
        Escrow(msg.sender, _value, _price, _open, _to);  
        return (true);  
    }
    
     
     
    function recieveEscrowTransfer(address _sender, uint _no) external payable returns (bool success) { 
             
            require(escrowTransferInfo[_sender][_no].value != 0);  
        box[msg.sender] = this.boxChoice(box[msg.sender]);  
        if (msg.sender == _sender) {
            _transfer(this, msg.sender, escrowTransferInfo[_sender][_no].value);  
            escrowTransferInfo[_sender][_no].value = 0;  
            Escrow(_sender, 0, msg.value, escrowTransferInfo[_sender][_no].open, msg.sender);  
            return (true);
        } else {
            require(msg.value >= escrowTransferInfo[_sender][_no].price);  
            if (escrowTransferInfo[_sender][_no].open == false) {
                require(msg.sender == escrowTransferInfo[_sender][_no].to);  
                }
            _transfer(this, msg.sender, escrowTransferInfo[_sender][_no].value);   
            _sender.transfer(msg.value);  
            escrowTransferInfo[_sender][_no].value = 0;  
            Escrow(_sender, 0, msg.value, escrowTransferInfo[_sender][_no].open, msg.sender);  
            return (true);  
        }
    }
}