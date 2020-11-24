 

pragma solidity ^0.4.11;

 

 
 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract AirSwapExchange {

     
    mapping (bytes32 => bool) public fills;

     
    event Filled(address indexed makerAddress, uint makerAmount, address indexed makerToken, address takerAddress, uint takerAmount, address indexed takerToken, uint256 expiration, uint256 nonce);
    event Canceled(address indexed makerAddress, uint makerAmount, address indexed makerToken, address takerAddress, uint takerAmount, address indexed takerToken, uint256 expiration, uint256 nonce);

     
    event Failed(uint code, address indexed makerAddress, uint makerAmount, address indexed makerToken, address takerAddress, uint takerAmount, address indexed takerToken, uint256 expiration, uint256 nonce);

     
    function fill(address makerAddress, uint makerAmount, address makerToken,
                  address takerAddress, uint takerAmount, address takerToken,
                  uint256 expiration, uint256 nonce, uint8 v, bytes32 r, bytes32 s) payable {

        if (makerAddress == takerAddress) {
            msg.sender.transfer(msg.value);
            Failed(1,
            makerAddress, makerAmount, makerToken,
            takerAddress, takerAmount, takerToken,
            expiration, nonce);
            return;
        }

         
        if (expiration < now) {
            msg.sender.transfer(msg.value);
            Failed(2,
                makerAddress, makerAmount, makerToken,
                takerAddress, takerAmount, takerToken,
                expiration, nonce);
            return;
        }

         
        bytes32 hash = validate(makerAddress, makerAmount, makerToken,
            takerAddress, takerAmount, takerToken,
            expiration, nonce, v, r, s);

         
        if (fills[hash]) {
            msg.sender.transfer(msg.value);
            Failed(3,
                makerAddress, makerAmount, makerToken,
                takerAddress, takerAmount, takerToken,
                expiration, nonce);
            return;
        }

         
        if (takerToken == address(0x0)) {

             
            if (msg.value == takerAmount) {

                 
                fills[hash] = true;

                 
                 
                assert(transfer(makerAddress, takerAddress, makerAmount, makerToken));

                 
                makerAddress.transfer(msg.value);

                 
                Filled(makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);

            } else {
                msg.sender.transfer(msg.value);
                Failed(4,
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);
            }

        } else {
             
             
            if (msg.value != 0) {
                msg.sender.transfer(msg.value);
                Failed(5,
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);
                return;
            }

            if (takerAddress == msg.sender) {

                 
                fills[hash] = true;

                 
                 
                 
                assert(trade(makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken));

                 
                Filled(
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);

            } else {
                Failed(6,
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);
            }
        }
    }

     
    function cancel(address makerAddress, uint makerAmount, address makerToken,
                    address takerAddress, uint takerAmount, address takerToken,
                    uint256 expiration, uint256 nonce, uint8 v, bytes32 r, bytes32 s) {

         
        bytes32 hash = validate(makerAddress, makerAmount, makerToken,
            takerAddress, takerAmount, takerToken,
            expiration, nonce, v, r, s);

         
        if (msg.sender == makerAddress) {

             
            if (fills[hash] == false) {

                 
                fills[hash] = true;

                 
                Canceled(makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);

            } else {
                Failed(7,
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);
            }
        }
    }

     
    function trade(address makerAddress, uint makerAmount, address makerToken,
                   address takerAddress, uint takerAmount, address takerToken) private returns (bool) {
        return (transfer(makerAddress, takerAddress, makerAmount, makerToken) &&
        transfer(takerAddress, makerAddress, takerAmount, takerToken));
    }

     
    function transfer(address from, address to, uint amount, address token) private returns (bool) {
        require(ERC20(token).transferFrom(from, to, amount));
        return true;
    }

     
    function validate(address makerAddress, uint makerAmount, address makerToken,
                      address takerAddress, uint takerAmount, address takerToken,
                      uint256 expiration, uint256 nonce, uint8 v, bytes32 r, bytes32 s) private returns (bytes32) {

         
        bytes32 hashV = keccak256(makerAddress, makerAmount, makerToken,
            takerAddress, takerAmount, takerToken,
            expiration, nonce);

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = sha3(prefix, hashV);

        require(ecrecover(prefixedHash, v, r, s) == makerAddress);

        return hashV;
    }
}