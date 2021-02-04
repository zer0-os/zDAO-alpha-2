const Web3 = require("web3");
const truffleAssert = require("truffle-assertions");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
const Matrix = artifacts.require("Matrix");
const VotingAppFactory = artifacts.require("VotingAppFactory");
const Cortex = artifacts.require("Cortex");
const Synaps = artifacts.require("Synaps");
const VotingApp = artifacts.require("VotingApp");

contract("Matrix", (accounts) => {
  console.log("starting tests");
  let account_one = accounts[0];
  let account_two = accounts[1];
  let matrix;
  let firstCortexAddress;
  let cortexy;
  let synapsAdd;
  let synaps;
  let votingAppAdd;
  let votingApp;
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

    assert.equal (
      false,
      isDelegate,
      "Cortexy assaigned as delegate error"
    )

    console.log("Cortexy is deployed with the proper permissions for itself");
  })
/////////////////////////////////////////////////////////////////////////////
  it("should create a proposal to install an TokenLock neuron to the cortex", async () => {
    console.log("Instantiating voting app");
    votingApp = await VotingApp.at(await cortexy.installedNeurons(0));
    console.log(votingApp.address);
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
    }, ["TokenLock", "0", neuroGenEncodedData]);
    console.log("calling proposal which will both create the TokenLock AND connect it");
    await votingApp.newProposal(
     firstCortexAddress,
     0,
     "fake prop hash here",
     encodedProposalData
   );
   let proposalInfo = await votingApp.proposals(0);
    console.log("Proposal created");
  })
  ////////////////////////////////////////////////////////////////////////////
  it("should allow for voting/execution of proposal", async () => {
    console.log("vote")
    await votingApp.vote(0, true);
    console.log("execute");
    let TokenLockAddress = await cortexy.installedNeurons(0);
    console.log("Address of Cortexys TokenLock: " + TokenLockAddress);
    console.log("Proposal based neuroGenesis success!");
  })
  ////////////////////////////////////////////////////////////////////////////
});
