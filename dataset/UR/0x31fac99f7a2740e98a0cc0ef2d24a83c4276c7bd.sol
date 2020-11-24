 

pragma solidity ^0.4.23;

 
contract MonarchyGame {
     
     
     
     
     
     
     
     
    struct Vars {
         
        address monarch;         
        uint64 prizeGwei;        
        uint32 numOverthrows;    

         
        uint32 blockEnded;       
        uint32 prevBlock;        
        bool isPaid;             
        bytes23 decree;          
    }

     
     
    struct Settings {
         
        address collector;        
        uint64 initialPrizeGwei;  
         
        uint64 feeGwei;           
        int64 prizeIncrGwei;      
        uint32 reignBlocks;       
    }

    Vars vars;
    Settings settings;
    uint constant version = 1;

    event SendPrizeError(uint time, string msg);
    event Started(uint time, uint initialBlocks);
    event OverthrowOccurred(uint time, address indexed newMonarch, bytes23 decree, address indexed prevMonarch, uint fee);
    event OverthrowRefundSuccess(uint time, string msg, address indexed recipient, uint amount);
    event OverthrowRefundFailure(uint time, string msg, address indexed recipient, uint amount);
    event SendPrizeSuccess(uint time, address indexed redeemer, address indexed recipient, uint amount, uint gasLimit);
    event SendPrizeFailure(uint time, address indexed redeemer, address indexed recipient, uint amount, uint gasLimit);
    event FeesSent(uint time, address indexed collector, uint amount);

    constructor(
        address _collector,
        uint _initialPrize,
        uint _fee,
        int _prizeIncr,
        uint _reignBlocks,
        uint _initialBlocks
    )
        public
        payable
    {
        require(_initialPrize >= 1e9);                 
        require(_initialPrize < 1e6 * 1e18);           
        require(_initialPrize % 1e9 == 0);             
        require(_fee >= 1e6);                          
        require(_fee < 1e6 * 1e18);                    
        require(_fee % 1e9 == 0);                      
        require(_prizeIncr <= int(_fee));              
        require(_prizeIncr >= -1*int(_initialPrize));  
        require(_prizeIncr % 1e9 == 0);                
        require(_reignBlocks >= 1);                    
        require(_initialBlocks >= 1);                  
        require(msg.value == _initialPrize);           

         
         
         
         
        settings.collector = _collector;
        settings.initialPrizeGwei = uint64(_initialPrize / 1e9);
        settings.feeGwei = uint64(_fee / 1e9);
        settings.prizeIncrGwei = int64(_prizeIncr / 1e9);
        settings.reignBlocks = uint32(_reignBlocks);

         
        vars.prizeGwei = settings.initialPrizeGwei;
        vars.monarch = _collector;
        vars.prevBlock = uint32(block.number);
        vars.blockEnded = uint32(block.number + _initialBlocks);

        emit Started(now, _initialBlocks);
    }


     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function()
        public
        payable
    {
        overthrow(0);
    }

    function overthrow(bytes23 _decree)
        public
        payable
    {
        if (isEnded())
            return errorAndRefund("Game has already ended.");
        if (msg.sender == vars.monarch)
            return errorAndRefund("You are already the Monarch.");
        if (msg.value != fee())
            return errorAndRefund("Value sent must match fee.");

         
        int _newPrizeGwei = int(vars.prizeGwei) + settings.prizeIncrGwei;
        uint32 _newBlockEnded = uint32(block.number) + settings.reignBlocks;
        uint32 _newNumOverthrows = vars.numOverthrows + 1;
        address _prevMonarch = vars.monarch;
        bool _isClean = (block.number != vars.prevBlock);

         
        if (_newPrizeGwei < 0)
            return errorAndRefund("Overthrowing would result in a negative prize.");

         
        bool _wasRefundSuccess;
        if (!_isClean) {
            _wasRefundSuccess = _prevMonarch.send(msg.value);   
        }

         
         
         
        if (_isClean) {
            vars.monarch = msg.sender;
            vars.numOverthrows = _newNumOverthrows;
            vars.prizeGwei = uint64(_newPrizeGwei);
            vars.blockEnded = _newBlockEnded;
            vars.prevBlock = uint32(block.number);
            vars.decree = _decree;
        }
        if (!_isClean && _wasRefundSuccess){
             
             
            vars.monarch = msg.sender;
            vars.decree = _decree;
        }
        if (!_isClean && !_wasRefundSuccess){
            vars.monarch = msg.sender;   
            vars.prizeGwei = uint64(_newPrizeGwei);
            vars.numOverthrows = _newNumOverthrows;
            vars.decree = _decree;
        }

         
        if (!_isClean){
            if (_wasRefundSuccess)
                emit OverthrowRefundSuccess(now, "Another overthrow occurred on the same block.", _prevMonarch, msg.value);
            else
                emit OverthrowRefundFailure(now, ".send() failed.", _prevMonarch, msg.value);
        }
        emit OverthrowOccurred(now, msg.sender, _decree, _prevMonarch, msg.value);
    }
         
         
        function errorAndRefund(string _msg)
            private
        {
            require(msg.sender.call.value(msg.value)());
            emit OverthrowRefundSuccess(now, _msg, msg.sender, msg.value);
        }


     
     
     

     
    function sendPrize(uint _gasLimit)
        public
        returns (bool _success, uint _prizeSent)
    {
         
        if (!isEnded()) {
            emit SendPrizeError(now, "The game has not ended.");
            return (false, 0);
        }
        if (vars.isPaid) {
            emit SendPrizeError(now, "The prize has already been paid.");
            return (false, 0);
        }

        address _winner = vars.monarch;
        uint _prize = prize();
        bool _paySuccessful = false;

         
        vars.isPaid = true;
        if (_gasLimit == 0) {
            _paySuccessful = _winner.call.value(_prize)();
        } else {
            _paySuccessful = _winner.call.value(_prize).gas(_gasLimit)();
        }

         
        if (_paySuccessful) {
            emit SendPrizeSuccess({
                time: now,
                redeemer: msg.sender,
                recipient: _winner,
                amount: _prize,
                gasLimit: _gasLimit
            });
            return (true, _prize);
        } else {
            vars.isPaid = false;
            emit SendPrizeFailure({
                time: now,
                redeemer: msg.sender,
                recipient: _winner,
                amount: _prize,
                gasLimit: _gasLimit
            });
            return (false, 0);          
        }
    }
    
     
    function sendFees()
        public
        returns (uint _feesSent)
    {
        _feesSent = fees();
        if (_feesSent == 0) return;
        require(settings.collector.call.value(_feesSent)());
        emit FeesSent(now, settings.collector, _feesSent);
    }



     
     
     

     
    function monarch() public view returns (address) {
        return vars.monarch;
    }
    function prize() public view returns (uint) {
        return uint(vars.prizeGwei) * 1e9;
    }
    function numOverthrows() public view returns (uint) {
        return vars.numOverthrows;
    }
    function blockEnded() public view returns (uint) {
        return vars.blockEnded;
    }
    function prevBlock() public view returns (uint) {
        return vars.prevBlock;
    }
    function isPaid() public view returns (bool) {
        return vars.isPaid;
    }
    function decree() public view returns (bytes23) {
        return vars.decree;
    }
     

     
    function collector() public view returns (address) {
        return settings.collector;
    }
    function initialPrize() public view returns (uint){
        return uint(settings.initialPrizeGwei) * 1e9;
    }
    function fee() public view returns (uint) {
        return uint(settings.feeGwei) * 1e9;
    }
    function prizeIncr() public view returns (int) {
        return int(settings.prizeIncrGwei) * 1e9;
    }
    function reignBlocks() public view returns (uint) {
        return settings.reignBlocks;
    }
     

     
    function isEnded() public view returns (bool) {
        return block.number > vars.blockEnded;
    }
    function getBlocksRemaining() public view returns (uint) {
        if (isEnded()) return 0;
        return (vars.blockEnded - block.number) + 1;
    }
    function fees() public view returns (uint) {
        uint _balance = address(this).balance;
        return vars.isPaid ? _balance : _balance - prize();
    }
    function totalFees() public view returns (uint) {
        int _feePerOverthrowGwei = int(settings.feeGwei) - settings.prizeIncrGwei;
        return uint(_feePerOverthrowGwei * vars.numOverthrows * 1e9);
    }
     
}