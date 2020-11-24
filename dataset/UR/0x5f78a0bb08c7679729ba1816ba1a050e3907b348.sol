 

pragma solidity ^0.4.19;

 
contract ERC20 {
  
     
    function totalSupply() public constant returns (uint256 supply);

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Fundraiser {

    event Beginning(
        bytes32 _causeSecret
    );

    event Participation(
        address _participant,
        bytes32 _message,
        uint256 _entries,
        uint256 _refund
    );

    event Raise(
        address _participant,
        uint256 _entries,
        uint256 _refund
    );

    event Revelation(
        bytes32 _causeMessage
    );

    event Selection(
        address _participant,
        bytes32 _participantMessage,
        bytes32 _causeMessage,
        bytes32 _ownerMessage
    );

    event Cancellation();

    event Withdrawal(
        address _address
    );

    struct Deployment {
        address _cause;
        address _causeWallet;
        uint256 _causeSplit;
        uint256 _participantSplit;
        address _owner;
        address _ownerWallet;
        uint256 _ownerSplit;
        bytes32 _ownerSecret;
        uint256 _valuePerEntry;
        uint256 _deployTime;
        uint256 _endTime;
        uint256 _expireTime;
        uint256 _destructTime;
        uint256 _entropy;
    }

    struct State {
        bytes32 _causeSecret;
        bytes32 _causeMessage;
        bool _causeWithdrawn;
        address _participant;
        bool _participantWithdrawn;
        bytes32 _ownerMessage;
        bool _ownerWithdrawn;
        bool _cancelled;
        uint256 _participants;
        uint256 _entries;
        uint256 _revealBlockNumber;
        uint256 _revealBlockHash;
    }

    struct Participant {
        bytes32 _message;
        uint256 _entries;
    }

    struct Fund {
        address _participant;
        uint256 _entries;
    }

    modifier onlyOwner() {
        require(msg.sender == deployment._owner);
        _;
    }

    modifier neverOwner() {
        require(msg.sender != deployment._owner);
        require(msg.sender != deployment._ownerWallet);
        _;
    }

    modifier onlyCause() {
        require(msg.sender == deployment._cause);
        _;
    }

    modifier neverCause() {
        require(msg.sender != deployment._cause);
        require(msg.sender != deployment._causeWallet);
        _;
    }

    modifier participationPhase() {
        require(now < deployment._endTime);
        _;
    }

    modifier recapPhase() {
        require((now >= deployment._endTime) && (now < deployment._expireTime));
        _;
    }

    modifier destructionPhase() {
        require(now >= deployment._destructTime);
        _;
    }
    
    Deployment public deployment;
    mapping(address => Participant) public participants;
    Fund[] private funds;
    State private _state;

    function Fundraiser(
        address _cause,
        address _causeWallet,
        uint256 _causeSplit,
        uint256 _participantSplit,
        address _ownerWallet,
        uint256 _ownerSplit,
        bytes32 _ownerSecret,
        uint256 _valuePerEntry,
        uint256 _endTime,
        uint256 _expireTime,
        uint256 _destructTime,
        uint256 _entropy
    ) public {
        require(_cause != 0x0);
        require(_causeWallet != 0x0);
        require(_causeSplit != 0);
        require(_participantSplit != 0);
        require(_ownerWallet != 0x0);
        require(_causeSplit + _participantSplit + _ownerSplit == 1000);
        require(_ownerSecret != 0x0);
        require(_valuePerEntry != 0);
        require(_endTime > now);  
        require(_expireTime > _endTime);  
        require(_destructTime > _expireTime);  
        require(_entropy > 0);

         
        deployment = Deployment(
            _cause,
            _causeWallet,
            _causeSplit,
            _participantSplit,
            msg.sender,
            _ownerWallet,
            _ownerSplit,
            _ownerSecret,
            _valuePerEntry,
            now,
            _endTime,
            _expireTime,
            _destructTime,
            _entropy
        );

    }

     
    function state() public view returns (
        bytes32 _causeSecret,
        bytes32 _causeMessage,
        bool _causeWithdrawn,
        address _participant,
        bytes32 _participantMessage,
        bool _participantWithdrawn,
        bytes32 _ownerMessage,
        bool _ownerWithdrawn,
        bool _cancelled,
        uint256 _participants,
        uint256 _entries
    ) {
        _causeSecret = _state._causeSecret;
        _causeMessage = _state._causeMessage;
        _causeWithdrawn = _state._causeWithdrawn;
        _participant = _state._participant;
        _participantMessage = participants[_participant]._message;
        _participantWithdrawn = _state._participantWithdrawn;
        _ownerMessage = _state._ownerMessage;
        _ownerWithdrawn = _state._ownerWithdrawn;
        _cancelled = _state._cancelled;
        _participants = _state._participants;
        _entries = _state._entries;
    }

     
    function balance() public view returns (uint256) {
         
        if (_state._participant != address(0)) {
             
            uint256 _split;
             
            if (msg.sender == deployment._cause) {
                if (_state._causeWithdrawn) {
                    return 0;
                }
                _split = deployment._causeSplit;
            } else if (msg.sender == _state._participant) {
                if (_state._participantWithdrawn) {
                    return 0;
                }
                _split = deployment._participantSplit;
            } else if (msg.sender == deployment._owner) {
                if (_state._ownerWithdrawn) {
                    return 0;
                }
                _split = deployment._ownerSplit;
            } else {
                return 0;
            }
             
            return _state._entries * deployment._valuePerEntry * _split / 1000;
        } else if (_state._cancelled) {
             
            Participant storage _participant = participants[msg.sender];
            return _participant._entries * deployment._valuePerEntry;
        }

        return 0;
    }

     
    function begin(bytes32 _secret) public participationPhase onlyCause {
        require(!_state._cancelled);  
        require(_state._causeSecret == 0x0);  
        require(_secret != 0x0);  

         
        _state._causeSecret = _secret;

         
        Beginning(_secret);
    }

     
    function participate(bytes32 _message) public participationPhase neverCause neverOwner payable {
        require(!_state._cancelled);  
        require(_state._causeSecret != 0x0);  
        require(_message != 0x0);  

         
        Participant storage _participant = participants[msg.sender];
        require(_participant._message == 0x0);
        require(_participant._entries == 0);

         
        var (_entries, _refund) = _raise(_participant);
         
        _participant._message = _message;
        _state._participants++;

         
        Participation(msg.sender, _message, _entries, _refund);
    }

     
    function _raise(Participant storage _participant) private returns (
        uint256 _entries,
        uint256 _refund
    ) {
         
        _entries = msg.value / deployment._valuePerEntry;
        require(_entries >= 1);  
         
        _participant._entries += _entries;
        _state._entries += _entries;

         
        uint256 _previousFundEntries = (funds.length > 0) ?
            funds[funds.length - 1]._entries : 0;
         
        Fund memory _fund = Fund(msg.sender, _previousFundEntries + _entries);
        funds.push(_fund);

         
        _refund = msg.value % deployment._valuePerEntry;
         
        if (_refund > 0) {
            msg.sender.transfer(_refund);
        }
    }

     
    function () public participationPhase neverCause neverOwner payable {
        require(!_state._cancelled);  
        require(_state._causeSecret != 0x0);  

         
        Participant storage _participant = participants[msg.sender];
        require(_participant._message != 0x0);  
         
        var (_entries, _refund) = _raise(_participant);
        
         
        Raise(msg.sender, _entries, _refund);
    }

     
    function reveal(bytes32 _message) public recapPhase onlyCause {
        require(!_state._cancelled);  
        require(_state._causeMessage == 0x0);  
        require(_state._revealBlockNumber == 0);  
        require(_decode(_state._causeSecret, _message));  

         
        _state._causeMessage = _message;
         
        _state._revealBlockNumber = block.number;

         
        Revelation(_message);
    }

     
    function _decode(bytes32 _secret, bytes32 _message) private view returns (bool) {
        return _secret == keccak256(_message, msg.sender);
    }

     
     
    function end(bytes32 _message) public recapPhase onlyOwner {
        require(!_state._cancelled);  
        require(_state._causeMessage != 0x0);  
        require(_state._revealBlockNumber != 0);  
        require(_state._ownerMessage == 0x0);  
        require(_decode(deployment._ownerSecret, _message));  
        require(block.number > _state._revealBlockNumber);  

         
        _state._revealBlockHash = uint256(block.blockhash(_state._revealBlockNumber));
        require(_state._revealBlockHash != 0);
         
        _state._ownerMessage = _message;

        bytes32 _randomNumber;
        address _participant;
        bytes32 _participantMessage;
         
        for (uint256 i = 0; i < deployment._entropy; i++) {
             
            _randomNumber = keccak256(
                _message,
                _state._causeMessage,
                _state._revealBlockHash,
                _participantMessage
            );
             
            uint256 _entry = uint256(_randomNumber) % _state._entries;
            _participant = _findParticipant(_entry);
            _participantMessage = participants[_participant]._message;
        }

         
        _state._participant = _participant;
        
         
        Selection(
            _state._participant,
            _participantMessage,
            _state._causeMessage,
            _message
        );
    }

     
    function _findParticipant(uint256 _entry) private view returns (address)  {
        uint256 _leftFundIndex = 0;
        uint256 _rightFundIndex = funds.length - 1;
         
        while (true) {
             
            if (_leftFundIndex == _rightFundIndex) {
                return funds[_leftFundIndex]._participant;
            }
             
            uint256 _midFundIndex =
                _leftFundIndex + ((_rightFundIndex - _leftFundIndex) / 2);
            uint256 _nextFundIndex = _midFundIndex + 1;
             
            Fund memory _midFund = funds[_midFundIndex];
            Fund memory _nextFund = funds[_nextFundIndex];
             
            if (_entry >= _midFund._entries) {
                if (_entry < _nextFund._entries) {
                     
                    return _nextFund._participant;
                }
                 
                _leftFundIndex = _nextFundIndex;
            } else {
                 
                _rightFundIndex = _midFundIndex;
            }
        }
    }

     
     
    function cancel() public {
        require(!_state._cancelled);  
        require(_state._participant == address(0));  
        
         
        if ((msg.sender != deployment._owner) && (msg.sender != deployment._cause)) {
            require((now >= deployment._expireTime) && (now < deployment._destructTime));
        }

         
        _state._cancelled = true;

         
        Cancellation();
    }

     
     
    function withdraw() public {
         
        uint256 _balance = balance();
        require (_balance > 0);  

        address _wallet;
         
        if (_state._participant != address(0)) {

             
            if (msg.sender == deployment._cause) {
                _state._causeWithdrawn = true;
                _wallet = deployment._causeWallet;
            } else if (msg.sender == _state._participant) {
                _state._participantWithdrawn = true;
                _wallet = _state._participant;
            } else if (msg.sender == deployment._owner) {
                _state._ownerWithdrawn = true;
                _wallet = deployment._ownerWallet;
            } else {
                revert();
            }

        } else if (_state._cancelled) {

             
            Participant storage _participant = participants[msg.sender];
            _participant._entries = 0;
            _wallet = msg.sender;

        } else {
             
            revert();
        }

         
        _wallet.transfer(_balance);
         
        Withdrawal(msg.sender);
    }

     
    function destroy() public destructionPhase onlyOwner {
         
        selfdestruct(msg.sender);
    }

     
     
    function recover(address _token) public onlyOwner {
        ERC20 _erc20 = ERC20(_token);
        uint256 _balance = _erc20.balanceOf(this);
        require(_erc20.transfer(deployment._owner, _balance));
    }
}