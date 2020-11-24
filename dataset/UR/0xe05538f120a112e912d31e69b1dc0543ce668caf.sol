     
    function freeze() public {
         
        require(!freezed);
         
        require((msg.sender == addr_team) || (msg.sender == addr_miner) || (msg.sender == addr_ico) || (msg.sender == addr_org));
         
        permits[msg.sender] = 1;
         
        uint sum = permits[addr_team] + permits[addr_miner] + permits[addr_ico] + permits[addr_org];
        if (sum >= 2) {
             
            freezed = true;
        }
        emit Freeze(msg.sender, sum);
    }
}
