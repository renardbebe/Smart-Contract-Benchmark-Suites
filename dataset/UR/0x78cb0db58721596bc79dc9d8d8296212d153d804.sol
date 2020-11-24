 

pragma solidity ^0.4.15;

 
contract PlayToken {
    uint256 public totalSupply = 0;
    string public name = "PLAY";
    uint8 public decimals = 18;
    string public symbol = "PLY";
    string public version = '1';

    address public controller;
    bool public controllerLocked = false;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

     
    function PlayToken(address _controller) {
        controller = _controller;
    }

     
    function setController(address _newController) onlyController {
        require(! controllerLocked);
        controller = _newController;
    }

     
    function lockController() onlyController {
        controllerLocked = true;
    }

     
    function mint(address _receiver, uint256 _value) onlyController {
        balances[_receiver] += _value;
        totalSupply += _value;
         
        Transfer(0, _receiver, _value);
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
         
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

     
    function withdrawTokens(ITransferable _token, address _to, uint256 _amount) onlyController {
        _token.transfer(_to, _amount);
    }
}

 
contract P4PGame {
    address public owner;
    address public pool;
    PlayToken playToken;
    bool public active = true;

    event GamePlayed(bytes32 hash, bytes32 boardEndState);
    event GameOver();

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyIfActive() {
        require(active);
        _;
    }

     
    function P4PGame(address _tokenAddr, address _poolAddr) {
        owner = msg.sender;
        playToken = PlayToken(_tokenAddr);
        pool = _poolAddr;
    }

     
    function setTokenController(address _controller) onlyOwner {
        playToken.setController(_controller);
    }

     
    function lockTokenController() onlyOwner {
        playToken.lockController();
    }

     
    function setPoolContract(address _pool) onlyOwner {
        pool = _pool;
    }

     
    function addGame(bytes32 hash, bytes32 board) onlyOwner onlyIfActive {
        GamePlayed(hash, board);
    }

     
    function distributeTokens(address[] receivers, uint16[] amounts) onlyOwner onlyIfActive {
        require(receivers.length == amounts.length);
        var totalAmount = distributeTokensImpl(receivers, amounts);
        payoutPool(totalAmount);
    }

     
    function shutdown() onlyOwner {
        active = false;
        GameOver();
    }

    function getTokenAddress() constant returns(address) {
        return address(playToken);
    }

     

     
    function distributeTokensImpl(address[] receivers, uint16[] amounts) internal returns(uint256) {
        uint256 totalAmount = 0;
        for (uint i = 0; i < receivers.length; i++) {
             
            playToken.mint(receivers[i], uint256(amounts[i]) * 1e18);
            totalAmount += amounts[i];
        }
        return totalAmount;
    }

     
    function payoutPool(uint256 amount) internal {
        require(pool != 0);
        playToken.mint(pool, amount * 1e18);
    }
}