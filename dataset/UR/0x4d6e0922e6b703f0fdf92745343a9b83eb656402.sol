 

pragma solidity ^0.4.17;

library ECVerify {

    function ecverify(bytes32 hash, bytes signature) internal pure returns (address signature_address) {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))

             
            v := byte(0, mload(add(signature, 96)))
        }

         
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        signature_address = ecrecover(hash, v, r, s);

         
        require(signature_address != 0x0);

        return signature_address;
    }
}
 
contract Token {
     

     
    uint256 public totalSupply;

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  


     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
}
 
contract RaidenMicroTransferChannels {

     

    uint32 public challenge_period;

     
    string public constant version = '0.1.0';

     
     
     
     
    uint256 public constant channel_deposit_bugbounty_limit = 10 ** 18 * 100;

    Token public token;

    mapping (bytes32 => Channel) public channels;
    mapping (bytes32 => ClosingRequest) public closing_requests;

     
    struct Channel {
         
         
        uint192 deposit;

         
         
         
        uint32 open_block_number;
    }

    struct ClosingRequest {
        uint192 closing_balance;
        uint32 settle_block_number;
    }

     

    event ChannelCreated(
        address indexed _sender,
        address indexed _receiver,
        uint192 _deposit);
    event ChannelToppedUp (
        address indexed _sender,
        address indexed _receiver,
        uint32 indexed _open_block_number,
        uint192 _added_deposit);
    event ChannelCloseRequested(
        address indexed _sender,
        address indexed _receiver,
        uint32 indexed _open_block_number,
        uint192 _balance);
    event ChannelSettled(
        address indexed _sender,
        address indexed _receiver,
        uint32 indexed _open_block_number,
        uint192 _balance);


     

     
     
     
     
     
    function RaidenMicroTransferChannels(address _token_address, uint32 _challenge_period) public {
        require(_token_address != 0x0);
        require(addressHasCode(_token_address));
        require(_challenge_period >= 500);

        token = Token(_token_address);

         
        require(token.totalSupply() > 0);

        challenge_period = _challenge_period;
    }

     
     
     
     
     
     
     
    function getKey(
        address _sender_address,
        address _receiver_address,
        uint32 _open_block_number)
        public
        pure
        returns (bytes32 data)
    {
        return keccak256(_sender_address, _receiver_address, _open_block_number);
    }

     
     
     
     
     
     
     
     
    function verifyBalanceProof(
        address _receiver_address,
        uint32 _open_block_number,
        uint192 _balance,
        bytes _balance_msg_sig)
        public
        view
        returns (address)
    {
         
         
         
         
         
         
        bytes32 message_hash = keccak256(
          keccak256('address receiver', 'uint32 block_created', 'uint192 balance', 'address contract'),
          keccak256(_receiver_address, _open_block_number, _balance, address(this))
        );

         
        address signer = ECVerify.ecverify(message_hash, _balance_msg_sig);
        return signer;
    }

     

     
     
     
     
     
    function tokenFallback(address _sender_address, uint256 _deposit, bytes _data) external {
         
        require(msg.sender == address(token));

        uint192 deposit = uint192(_deposit);
        require(deposit == _deposit);

        uint length = _data.length;

         
         
        require(length == 20 || length == 24);

        address receiver = addressFromData(_data);

        if(length == 20) {
            createChannelPrivate(_sender_address, receiver, deposit);
        } else {
            uint32 open_block_number = blockNumberFromData(_data);
            updateInternalBalanceStructs(
                _sender_address,
                receiver,
                open_block_number,
                deposit
            );
        }
    }

     
     
     
     
    function createChannelERC20(address _receiver_address, uint192 _deposit) external {
        createChannelPrivate(msg.sender, _receiver_address, _deposit);

         
         
        require(token.transferFrom(msg.sender, address(this), _deposit));
    }

     
     
     
     
     
    function topUpERC20(
        address _receiver_address,
        uint32 _open_block_number,
        uint192 _added_deposit)
        external
    {
        updateInternalBalanceStructs(
            msg.sender,
            _receiver_address,
            _open_block_number,
            _added_deposit
        );

         
         
         
        require(token.transferFrom(msg.sender, address(this), _added_deposit));
    }

     
     
     
     
     
     
     
    function uncooperativeClose(
        address _receiver_address,
        uint32 _open_block_number,
        uint192 _balance,
        bytes _balance_msg_sig)
        external
    {
        address sender = verifyBalanceProof(_receiver_address, _open_block_number, _balance, _balance_msg_sig);

        if(msg.sender == _receiver_address) {
            settleChannel(sender, _receiver_address, _open_block_number, _balance);
        } else {
            require(msg.sender == sender);
            initChallengePeriod(_receiver_address, _open_block_number, _balance);
        }
    }

     
     
     
     
     
     
     
     
    function cooperativeClose(
        address _receiver_address,
        uint32 _open_block_number,
        uint192 _balance,
        bytes _balance_msg_sig,
        bytes _closing_sig)
        external
    {
         
        address receiver = ECVerify.ecverify(keccak256(_balance_msg_sig), _closing_sig);
        require(receiver == _receiver_address);

         
        address sender = verifyBalanceProof(_receiver_address, _open_block_number, _balance, _balance_msg_sig);
        require(msg.sender == sender);

        settleChannel(sender, receiver, _open_block_number, _balance);
    }

     
     
     
     
     
     
    function getChannelInfo(
        address _sender_address,
        address _receiver_address,
        uint32 _open_block_number)
        external
        constant
        returns (bytes32, uint192, uint32, uint192)
    {
        bytes32 key = getKey(_sender_address, _receiver_address, _open_block_number);
        require(channels[key].open_block_number > 0);

        return (
            key,
            channels[key].deposit,
            closing_requests[key].settle_block_number,
            closing_requests[key].closing_balance
        );
    }

     
     
     
     
     
    function settle(address _receiver_address, uint32 _open_block_number) external {
        bytes32 key = getKey(msg.sender, _receiver_address, _open_block_number);

         
        require(closing_requests[key].settle_block_number > 0);

         
	    require(block.number > closing_requests[key].settle_block_number);

        settleChannel(msg.sender, _receiver_address, _open_block_number,
            closing_requests[key].closing_balance
        );
    }

     

     
     
     
     
     
    function createChannelPrivate(address _sender_address, address _receiver_address, uint192 _deposit) private {
        require(_deposit <= channel_deposit_bugbounty_limit);

        uint32 open_block_number = uint32(block.number);

         
        bytes32 key = getKey(_sender_address, _receiver_address, open_block_number);

        require(channels[key].deposit == 0);
        require(channels[key].open_block_number == 0);
        require(closing_requests[key].settle_block_number == 0);

         
        channels[key] = Channel({deposit: _deposit, open_block_number: open_block_number});
        ChannelCreated(_sender_address, _receiver_address, _deposit);
    }

     
     
     
     
     
     
    function updateInternalBalanceStructs(
        address _sender_address,
        address _receiver_address,
        uint32 _open_block_number,
        uint192 _added_deposit)
        private
    {
        require(_added_deposit > 0);
        require(_open_block_number > 0);

        bytes32 key = getKey(_sender_address, _receiver_address, _open_block_number);

        require(channels[key].deposit > 0);
        require(closing_requests[key].settle_block_number == 0);
        require(channels[key].deposit + _added_deposit <= channel_deposit_bugbounty_limit);

        channels[key].deposit += _added_deposit;
        assert(channels[key].deposit > _added_deposit);
        ChannelToppedUp(_sender_address, _receiver_address, _open_block_number, _added_deposit);
    }


     
     
     
     
     
    function initChallengePeriod(
        address _receiver_address,
        uint32 _open_block_number,
        uint192 _balance)
        private
    {
        bytes32 key = getKey(msg.sender, _receiver_address, _open_block_number);

        require(closing_requests[key].settle_block_number == 0);
        require(_balance <= channels[key].deposit);

         
        closing_requests[key].settle_block_number = uint32(block.number) + challenge_period;
        closing_requests[key].closing_balance = _balance;
        ChannelCloseRequested(msg.sender, _receiver_address, _open_block_number, _balance);
    }

     
     
     
     
     
     
     
    function settleChannel(
        address _sender_address,
        address _receiver_address,
        uint32 _open_block_number,
        uint192 _balance)
        private
    {
        bytes32 key = getKey(_sender_address, _receiver_address, _open_block_number);
        Channel memory channel = channels[key];

        require(channel.open_block_number > 0);
        require(_balance <= channel.deposit);

         
         
         
        delete channels[key];
        delete closing_requests[key];

         
        require(token.transfer(_receiver_address, _balance));

         
        require(token.transfer(_sender_address, channel.deposit - _balance));

        ChannelSettled(_sender_address, _receiver_address, _open_block_number, _balance);
    }

     

     
     
     
    function addressFromData (bytes b) internal pure returns (address) {
        bytes20 addr;
        assembly {
             
             
            addr := mload(add(b, 0x20))
        }
        return address(addr);
    }

     
     
     
    function blockNumberFromData(bytes b) internal pure returns (uint32) {
        bytes4 block_number;
        assembly {
             
             
            block_number := mload(add(b, 0x34))
        }
        return uint32(block_number);
    }

     
     
     
    function addressHasCode(address _contract) internal constant returns (bool) {
        uint size;
        assembly {
            size := extcodesize(_contract)
        }

        return size > 0;
    }
}