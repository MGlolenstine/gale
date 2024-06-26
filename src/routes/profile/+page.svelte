<script lang="ts">
	import Popup from '$lib/Popup.svelte';
	import { invokeCommand } from '$lib/invoke';
	import type { Dependant, Mod, QueryModsArgs, RemoveModResponse } from '$lib/models';
	import ModList from '$lib/modlist/ModList.svelte';
	import { currentGame, currentProfile } from '$lib/profile';
	import { isOutdated } from '$lib/util';
	import Icon from '@iconify/svelte';
	import { Button, Dialog } from 'bits-ui';

	let mods: Mod[];
	let activeMod: Mod | undefined;
	let queryArgs: QueryModsArgs;

	let dependants: Dependant[] = [];
	let removeDependantsPopupOpen = false;

	$: outdatedMods = mods?.filter((mod) => isOutdated(mod));

	$: {
		queryArgs;
		$currentProfile;
		$currentGame;
		refresh();
	}

	function refresh() {
		if (queryArgs) {
			invokeCommand<Mod[]>('query_mods_in_profile', { args: queryArgs }).then(
				(result) => (mods = result)
			);
		}
	}

	async function removeMod() {
		if (!activeMod) return;

		let response = await invokeCommand<RemoveModResponse>('remove_mod', {
			uuid: activeMod.uuid
		});

		if (response.type == 'removed') {
			activeMod = undefined;
			refresh();
			return;
		}

		dependants = response.content;
		removeDependantsPopupOpen = true;
	}

	function forceRemoveDependants() {
		let packageUuids = dependants.map((d) => d.uuid).concat(activeMod!.uuid);

		invokeCommand('force_remove_mods', { packageUuids }).then(() => {
			activeMod = undefined;
			dependants = [];
			refresh();
		});
	}
</script>

<ModList
	bind:mods
	bind:queryArgs
	bind:activeMod
	extraDropdownOptions={[
		{
			icon: 'mdi:delete',
			label: 'Uninstall',
			onClick: removeMod
		}
	]}
>
	<div slot="details">
		{#if activeMod && isOutdated(activeMod)}
			<Button.Root
				class="flex items-center justify-center w-full gap-2 py-2 rounded-lg mt-2
						bg-blue-600 hover:bg-blue-500 font-medium text-lg"
				on:click={() => {
					invokeCommand('update_mod', { uuid: activeMod?.uuid }).then(refresh);
				}}
			>
				<Icon icon="mdi:arrow-up-circle" class="text-xl align-middle" />
				Update
			</Button.Root>
		{/if}
	</div>
	<div slot="header">
		{#if outdatedMods?.length > 0}
			<div class="text-slate-200 bg-blue-600 ml-2 mr-6 mb-2 px-4 py-2 rounded-lg">
				<Icon icon="mdi:arrow-up-circle" class="text-xl mr-1 mb-0.5 inline" />
				There {outdatedMods.length === 1 ? 'is' : 'are'} <strong>{outdatedMods.length}</strong>
				updates available.
				<Button.Root
					class="underline"
					on:click={() => {
						invokeCommand('update_all').then(refresh);
					}}
				>
					Update all?
				</Button.Root>
			</div>
		{/if}
	</div>
</ModList>

{#if activeMod}
	<Popup title="Confirm removal" bind:open={removeDependantsPopupOpen}>
		<Dialog.Description class="text-slate-300">
			The following mods depend on {activeMod.name} and
			<strong>will be also be removed if you proceed:</strong>
			<ul class="mt-1">
				{#each dependants as dependant}
					<li>- {dependant.name}</li>
				{/each}
			</ul>
		</Dialog.Description>

		<div class="flex w-full justify-end mt-3 mr-0.5 gap-2">
			<Dialog.Close>
				<Button.Root class="rounded-xl px-4 py-2 text-slate-100 bg-gray-700 hover:bg-gray-600">
					Cancel
				</Button.Root>
			</Dialog.Close>
			<Dialog.Close>
				<Button.Root
					class="rounded-xl px-4 py-2 text-gray-200 bg-red-600 hover:bg-red-500"
					on:click={forceRemoveDependants}
				>
					Proceed
				</Button.Root>
			</Dialog.Close>
		</div>
	</Popup>
{/if}
