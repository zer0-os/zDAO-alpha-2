const Web3 = require("web3");
const truffleAssert = require("truffle-assertions");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
const Matrix = artifacts.require("Matrix");
const FrontalLobeFactory = artifacts.require("FrontalLobeFactory");
const Cortex = artifacts.require("Cortex");
const Synaps = artifacts.require("Synaps");
const FrontalLobe = artifacts.require("FrontalLobe");

contract("Matrix", (accounts) => {
  console.log("starting tests");
  let account_one = accounts[0];
  let account_two = accounts[1];
  let matrix;
  let firstCortexAddress;
  let cortexy;
  let synapsAdd;
  let synaps;
  let frontalLobeAdd;
  let frontalLobe;
  let synapsLobeAdd;

  before(async function () {
    matrix = await Matrix.deployed();
    console.log(matrix.address)
  });
/////////////////////////////////////////////////////////////////////////////
  it("should successfully deploy out a Cortex contract", async () => {
    console.log("Deploying Cortexy the Cortex");
    await matrix.createCortex(
      "Cortexy",
     "CortextBucks",
     "CTB",
     "0x0000000000000000000000000000000000000000",
     false,
     0
   );
    firstCortexAddress = await matrix.retrieveCortex("Cortexy");
    let nameTaken = await matrix.cortexNameTaken("Cortexy");
    cortexy = await Cortex.at(firstCortexAddress);
    console.log("test cortex created @:");
    console.log(firstCortexAddress);
    let cortexOwnerAdd = await cortexy.owner();
    console.log("Cortexy Owner: " + cortexOwnerAdd);
    console.log("name marked taken: " + nameTaken);
     synapsAdd = await cortexy.synapses(0);
    console.log("synaps address: " + synapsAdd);
    synaps = await Synaps.at(synapsAdd);
    let synOwner = await synaps.owner();
    console.log("Synaps Owner: " + synOwner);
    assert.equal(nameTaken, true, "Name wasnt recorded as taken for the cortex");
    assert.notEqual(
      0x0000000000000000000000000000000000000000,
      firstCortexAddress,
      "Matrix didnt store cortex contract data properly"
    )
    assert.notEqual(
      0x0000000000000000000000000000000000000000,
      synapsAdd,
      "Synaps not created"
    )
    let isDelegate = await cortexy.approvedDelegateCallContracts(cortexy.address);
    console.log("Is delegate in the cortex: " + isDelegate);
    let isMinter = await cortexy.approvedMintContracts(cortexy.address);
    console.log("Is minter in the cortex: " + isMinter);
    let isBurner = await cortexy.approvedBurnContracts(cortexy.address);
    console.log("Is burner in the cortex: " + isBurner);
    assert.equal (
      false,
      isDelegate,
      "Cortexy assaigned as delegate error"
    )
    assert.equal (
      true,
      isMinter,
      "Cortexy assaigned as Minter error"
    )
    assert.equal (
      true,
      isBurner,
      "Cortexy assaigned as Burner error"
    )
    console.log("Cortexy is deployed with the proper permissions for itself");
  })
/////////////////////////////////////////////////////////////////////////////
  it("should create a useable FrontalLobe for the cortex contract", async () => {
    console.log("Encoding FrontalLobe connectNeuron function And params");
    let frontalLobeEncodedData =  await web3.eth.abi.encodeFunctionCall({
      name: 'connectNeuron',
      type: 'function',
      inputs: [{
        type: 'address',
        name: '_synaps'
      },{
        type: 'uint256',
        name: '_quorum'
      },{
        type: 'uint256',
        name: '_proposalTime'
      },{
        type: 'bool',
        name: '_transferableRep'
      }]
    }, [synapsAdd, '60', '50000000000000000', "false"]);
    console.log("calling neuroGenesis");
    await cortexy.neuroGenesis("FrontalLobe", 0, frontalLobeEncodedData);
     frontalLobeAdd = await cortexy.installedNeurons(0);
    console.log("FrontalLobe address: " + frontalLobeAdd);

    assert.notEqual(
      0x0000000000000000000000000000000000000000,
      frontalLobeAdd,
      "FrontalLobe creation error"
    )
    frontalLobe = await FrontalLobe.at(frontalLobeAdd);
    let isDelegate = await cortexy.approvedDelegateCallContracts(frontalLobe.address);
    console.log("Is delegate in the cortex: " + isDelegate);
    let isMinter = await cortexy.approvedMintContracts(frontalLobe.address);
    console.log("Is minter in the cortex: " + isMinter);
    let isBurner = await cortexy.approvedBurnContracts(frontalLobe.address);
    console.log("Is burner in the cortex: " + isBurner);
    assert.equal (
      true,
      isDelegate,
      "FrontalLobe assaigned as delegate error"
    )
    assert.equal (
      true,
      isMinter,
      "FrontalLobe assaigned as Minter error"
    )
    assert.equal (
      true,
      isBurner,
      "FrontalLobe assaigned as Burner error"
    )
    console.log("transfering ownership of Cortexy to itself");
    await cortexy.transferOwnership(cortexy.address);
    let cortexOwnerAdd = await cortexy.owner();
    console.log("Cortexy Owner: " + cortexOwnerAdd);
        console.log("FrontalLobe successfully installed in cortexy with proper permissions");
  })
/////////////////////////////////////////////////////////////////////////////
  it("should create a proposal to add a minter to the FrontalLobe contract", async () => {
    console.log("encoding addMinter function call");
     synapsLobeAdd = await frontalLobe.synaps();
    console.log(synapsLobeAdd);
    let encodedMintData =  await web3.eth.abi.encodeFunctionCall({
      name: 'addMinter',
      type: 'function',
      inputs: [{
        type: 'address',
        name: '_minter'
      }]
    }, [account_two]);
    console.log("Creating addMinter proposal")
    await frontalLobe.newProposal(
     firstCortexAddress,
     0,
     "fake prop hash here",
     encodedMintData
   );
   let proposalInfo = await frontalLobe.proposals(1);
    console.log("Proposal successfully created");
  })
////////////////////////////////////////////////////////////////////////////
  it("should allow for voting/execution of proposal", async () => {
    let isMinterNow = await cortexy.approvedMintContracts(account_two);
    console.log("Can account two now mint? " + isMinterNow);
    console.log("voting and executing now");
    await frontalLobe.vote(1, true);
    isMinterNow = await cortexy.approvedMintContracts(account_two);
    console.log("Can account two now mint? " + isMinterNow);
    assert.equal(
      true,
      isMinterNow,
      "Minting function didnt execute"
    )
    console.log("Propoasl successful as was addminter Function call");
  })
  ////////////////////////////////////////////////////////////////////////////
  it("should create a proposal to proxyMint to account two in the FrontalLobe contract", async () => {
    console.log("encoding mint data");
    let encodedMintData =  await web3.eth.abi.encodeFunctionCall({
      name: 'proxyMint',
      type: 'function',
      inputs: [{
        type: 'address',
        name: '_to'
      },{
        type: 'uint256',
        name: '_amount'
      },{
        type: 'uint256',
        name: '_synapsID'
      }]
    }, [account_two, "12340516", "0"]);
    console.log("calling proposal");
    await frontalLobe.newProposal(
     firstCortexAddress,
     0,
     "fake prop hash here",
     encodedMintData
   );
   let proposalInfo = await frontalLobe.proposals(2);
    console.log("Proposal created");
  })
  ////////////////////////////////////////////////////////////////////////////
  it("should allow for voting/execution of proposal", async () => {
    console.log("retreiving balance of account 2");
    let synapsBal = await synaps.balanceOf(account_two);
    console.log("balance : " + synapsBal);
    console.log("vote")
    await frontalLobe.vote(2, true);
    console.log("execute");

    console.log("Retreive balance again");
    synapsBal = await synaps.balanceOf(account_two);
    console.log("balance : " + synapsBal);
    console.log("Proposal based synaps minitng success!");
  })
  ////////////////////////////////////////////////////////////////////////////
  it("should create a proposal to install an Axon neuron to the cortex", async () => {
    console.log("encoding proposal data");
    let neuroGenEncodedData =  await web3.eth.abi.encodeFunctionCall({
      name: 'connectNeuron',
      type: 'function',
      inputs: [{
        type: 'address',
        name: '_cortex'
      }]
    }, [firstCortexAddress]);

    let encodedProposalData =  await web3.eth.abi.encodeFunctionCall({
      name: 'neuroGenesis',
      type: 'function',
      inputs: [{
        type: 'string',
        name: '_neuronName'
      },{
        type: 'uint256',
        name: '_amount'
      },{
        type: 'bytes',
        name: 'call_data'
      }]
    }, ["Axon", "0", neuroGenEncodedData]);
    console.log("calling proposal which will both create the axon AND connect it");
    await frontalLobe.newProposal(
     firstCortexAddress,
     0,
     "fake prop hash here",
     encodedProposalData
   );
   let proposalInfo = await frontalLobe.proposals(3);
    console.log("Proposal created");
  })
  ////////////////////////////////////////////////////////////////////////////
  it("should allow for voting/execution of proposal", async () => {
    console.log("vote")
    await frontalLobe.vote(3, true);
    console.log("execute");
    let axonAddress = await cortexy.installedNeurons(0);
    console.log("Address of Cortexys Axon: " + axonAddress);
    console.log("Proposal based neuroGenesis success!");
  })
  ////////////////////////////////////////////////////////////////////////////
});
