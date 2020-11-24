 

 

pragma solidity 0.5.0;

interface Token {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

 
 
 
contract HSendBatchTokens {
    
    mapping (address => mapping (address => bool)) private wasAirdropped;

     
     
     
     
     
    function sendBatchTokens(
        address[] calldata _targets,
        address _token)
        external
        returns (bool success)
    {
        uint256 length = _targets.length;
        uint256 amount = 1 * 10 ** 18;
        Token token = Token(_token);
        require(
            token.transferFrom(
                msg.sender,
                address(this),
                (amount * length)
            )
        );
        for (uint256 i = 0; i < length; i++) {
            if (token.balanceOf(_targets[i]) > uint256(0)) continue;
            if(wasAirdropped[_token][_targets[i]]) continue;
            wasAirdropped[_token][_targets[i]] = true;
            require(
                token.transfer(
                    _targets[i],
                    amount
                )
            );
        }
        if (token.balanceOf(address(this)) > uint256(0)) {
            require(
                token.transfer(
                    msg.sender,
                    token.balanceOf(address(this))
                )
            );
        }
        success = true;
    }
    
     
     
     
     
     
    function hasReceivedAirdrop(
        address _token,
        address _target)
        external
        view
        returns (bool)
    {
        return wasAirdropped[_token][_target];
    }
}